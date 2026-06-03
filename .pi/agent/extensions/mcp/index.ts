/**
 * Pi MCP extension (lazy).
 *
 * Reads `~/.pi/agent/mcp.json` for server definitions and lazily spawns
 * each one on first tool call. The MCP server subprocess is held open
 * for the rest of the session, then closed on `session_shutdown`.
 *
 * Config shape:
 *
 *   {
 *     "servers": {
 *       "context7-mcp": {
 *         "command": "npx",
 *         "args": ["-y", "@upstash/context7-mcp"]
 *       },
 *       "tts": {
 *         "command": "tts-mcp",
 *         "env": { "RUST_LOG": "debug" }
 *       }
 *     }
 *   }
 *
 * Tools exposed:
 *   - mcp_<server>_list      (no args) -> { tools: [{ name, description, inputSchema }] }
 *   - mcp_<server>_call      (name, arguments) -> forwards to the server
 *   - mcp_<server>_resources (uri?) -> reads server resources
 *
 * The model gets a small, predictable surface per server regardless of how
 * many tools the server actually exposes. Discovery happens once on first
 * call; the result is cached for the rest of the session.
 *
 * Lazy by design: `session_start` only reads config and registers the
 * generic dispatcher tools. The MCP server process is not spawned until
 * the first `mcp_<server>_*` call, so pi startup is unaffected by MCP
 * cost (e.g. `npx -y` downloads).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import type {
	Tool as McpTool,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const CONFIG_PATH = join(homedir(), ".pi", "agent", "mcp.json");

interface ServerConfig {
	command: string;
	args?: string[];
	env?: Record<string, string>;
}

interface PiMcpConfig {
	servers?: Record<string, ServerConfig>;
}

/** Expand a leading `~` to the user's home directory. */
function expandHome(value: string): string {
	if (value === "~") return homedir();
	if (value.startsWith("~/")) return homedir() + value.slice(1);
	return value;
}

function loadConfig(): PiMcpConfig {
	try {
		const raw = readFileSync(CONFIG_PATH, "utf8");
		const parsed = JSON.parse(raw) as PiMcpConfig;
		if (parsed && typeof parsed === "object" && parsed.servers && typeof parsed.servers === "object") {
			for (const server of Object.values(parsed.servers)) {
				if (server.env) {
					for (const [k, v] of Object.entries(server.env)) {
						server.env[k] = expandHome(v);
					}
				}
			}
			return parsed;
		}
		console.warn(`[mcp] ${CONFIG_PATH} has unexpected shape; ignoring`);
		return {};
	} catch (err) {
		if ((err as NodeJS.ErrnoException).code !== "ENOENT") {
			console.warn(`[mcp] failed to read ${CONFIG_PATH}:`, err);
		}
		return {};
	}
}

// ---------------------------------------------------------------------------
// Tool name sanitization (pi requires `^[a-zA-Z][a-zA-Z0-9_]*$`, max 64)
// ---------------------------------------------------------------------------

const TOOL_NAME_RE = /^[a-zA-Z][a-zA-Z0-9_]*$/;

function sanitizeSegment(input: string): string {
	let s = input.replace(/[^a-zA-Z0-9_]/g, "_");
	if (!/^[a-zA-Z_]/.test(s)) s = "_" + s;
	return s;
}

function buildToolName(serverName: string, suffix: string): string {
	const full = `mcp_${sanitizeSegment(serverName)}_${suffix}`;
	return full.length > 64 ? full.slice(0, 64) : full;
}

function isValidToolName(name: string): boolean {
	return TOOL_NAME_RE.test(name) && name.length <= 64;
}

// ---------------------------------------------------------------------------
// MCP result → pi tool result
// ---------------------------------------------------------------------------

interface McpContentBlock {
	type: string;
	text?: string;
	data?: string;
	mimeType?: string;
	uri?: string;
	resource?: { text?: string; uri?: string };
}

function mcpResultToPiContent(
	content: McpContentBlock[],
): Array<{ type: "text"; text: string }> {
	return content.map((c) => {
		if (c.type === "text" && typeof c.text === "string") {
			return { type: "text", text: c.text };
		}
		if (c.type === "image") {
			return { type: "text", text: `[image: ${c.mimeType ?? "unknown"}, ${c.data?.length ?? 0} b64 chars]` };
		}
		if (c.type === "audio") {
			return { type: "text", text: `[audio: ${c.mimeType ?? "unknown"}, ${c.data?.length ?? 0} b64 chars]` };
		}
		if (c.type === "resource") {
			return { type: "text", text: c.resource?.text ?? `[resource: ${c.uri ?? c.resource?.uri ?? "?"}]` };
		}
		return { type: "text", text: JSON.stringify(c) };
	});
}

// ---------------------------------------------------------------------------
// Lazy server runtime
// ---------------------------------------------------------------------------

interface ServerState {
	name: string;
	config: ServerConfig;
	connectPromise: Promise<Client> | null;
	client: Client | null;
	tools: McpTool[] | null;
	resources: { uri: string; name: string; description?: string; mimeType?: string }[] | null;
}

function newServerState(name: string, config: ServerConfig): ServerState {
	return { name, config, connectPromise: null, client: null, tools: null, resources: null };
}

async function ensureConnected(state: ServerState, signal?: AbortSignal): Promise<Client> {
	if (state.client) return state.client;
	if (state.connectPromise) return state.connectPromise;

	state.connectPromise = (async () => {
		const client = new Client({ name: "pi", version: "0.1.0" }, { capabilities: {} });
		const transport = new StdioClientTransport({
			command: state.config.command,
			args: state.config.args ?? [],
			env: state.config.env,
		});
		await client.connect(transport, signal ? { signal } : undefined);
		state.client = client;
		state.connectPromise = null;
		return client;
	})().catch((err) => {
		state.connectPromise = null;
		throw err;
	});

	return state.connectPromise;
}

async function listTools(state: ServerState, signal?: AbortSignal): Promise<McpTool[]> {
	if (state.tools) return state.tools;
	const client = await ensureConnected(state, signal);
	const { tools } = await client.listTools({}, signal ? { signal } : undefined);
	state.tools = tools;
	return tools;
}

async function listResources(
	state: ServerState,
	signal?: AbortSignal,
): Promise<{ uri: string; name: string; description?: string; mimeType?: string }[]> {
	if (state.resources) return state.resources;
	const client = await ensureConnected(state, signal);
	try {
		const { resources } = await client.listResources({}, signal ? { signal } : undefined);
		state.resources = resources.map((r) => ({
			uri: r.uri,
			name: r.name,
			description: r.description,
			mimeType: r.mimeType,
		}));
	} catch {
		// Server doesn't support resources; treat as empty.
		state.resources = [];
	}
	return state.resources;
}

async function callTool(
	state: ServerState,
	name: string,
	args: Record<string, unknown> | undefined,
	signal?: AbortSignal,
): Promise<{ content?: McpContentBlock[]; isError?: boolean; structuredContent?: unknown }> {
	const client = await ensureConnected(state, signal);
	const result = await client.callTool(
		{ name, arguments: args ?? {} },
		undefined,
		signal ? { signal } : undefined,
	) as { content?: McpContentBlock[]; isError?: boolean; structuredContent?: unknown };
	return result;
}

async function readResource(
	state: ServerState,
	uri: string,
	signal?: AbortSignal,
): Promise<{ contents?: Array<{ text?: string; uri: string; mimeType?: string }> }> {
	const client = await ensureConnected(state, signal);
	return client.readResource({ uri }, signal ? { signal } : undefined) as {
		contents?: Array<{ text?: string; uri: string; mimeType?: string }>;
	};
}

function formatToolList(tools: McpTool[]): string {
	return tools
		.map((t) => {
			const desc = t.description ? `: ${t.description}` : "";
			return `- ${t.name}${desc}`;
		})
		.join("\n");
}

function formatToolForDiscovery(t: McpTool): {
	name: string;
	description: string;
	inputSchema: unknown;
} {
	return { name: t.name, description: t.description ?? "", inputSchema: t.inputSchema };
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function mcpExtension(pi: ExtensionAPI) {
	const config = loadConfig();
	const servers = config.servers ?? {};

	if (Object.keys(servers).length === 0) {
		return;
	}

	const states = new Map<string, ServerState>();
	for (const [name, serverCfg] of Object.entries(servers)) {
		if (!serverCfg || typeof serverCfg.command !== "string" || !serverCfg.command) {
			console.warn(`[mcp] server "${name}" has no command; skipping`);
			continue;
		}
		states.set(name, newServerState(name, serverCfg));
	}

	// For each server, register 3 dispatcher tools: list / call / resources.
	for (const [serverName, state] of states) {
		const listName = buildToolName(serverName, "list");
		const callName = buildToolName(serverName, "call");
		const resourcesName = buildToolName(serverName, "resources");

		if (isValidToolName(listName)) {
			pi.registerTool({
				name: listName,
				label: `MCP ${serverName}: list`,
				description:
					`List tools exposed by the MCP server "${serverName}". ` +
					`Returns tool names, descriptions, and JSON-Schema input schemas. ` +
					`Call this first to discover what's available, then use ` +
					`${callName} to invoke a specific tool.`,
				promptSnippet: `Discover tools on the ${serverName} MCP server`,
				promptGuidelines: [
					`Use ${listName} before ${callName} when you need to know what tools the ${serverName} MCP server exposes or what their argument shapes are.`,
				],
				parameters: Type.Object({}),
				async execute(_toolCallId, _params, signal) {
					try {
						const tools = await listTools(state, signal);
						return {
							content: [
								{
									type: "text" as const,
									text: `Tools on MCP server "${serverName}" (${tools.length}):\n\n${formatToolList(tools)}`,
								},
							],
							details: {
								server: serverName,
								tools: tools.map(formatToolForDiscovery),
							},
						};
					} catch (err) {
						return mcpErrorResult(err, serverName, "list");
					}
				},
			});
		}

		if (isValidToolName(callName)) {
			pi.registerTool({
				name: callName,
				label: `MCP ${serverName}: call`,
				description:
					`Invoke a tool on the MCP server "${serverName}". ` +
					`Pass the tool's ` +
					`"name" and an "arguments" object matching its inputSchema ` +
					`(use ${listName} to discover them).`,
				promptSnippet: `Call a tool on the ${serverName} MCP server`,
				promptGuidelines: [
					`Before calling ${callName}, prefer ${listName} if you are unsure of the tool's exact name or argument shape.`,
				],
				parameters: Type.Object({
					name: Type.String({ description: `Name of the tool on the "${serverName}" server` }),
					arguments: Type.Optional(
						Type.Record(Type.String(), Type.Unknown(), {
							description: "Arguments matching the tool's inputSchema",
						}),
					),
				}),
				async execute(_toolCallId, params, signal) {
					const toolName = String(params.name ?? "").trim();
					if (!toolName) {
						return {
							content: [{ type: "text" as const, text: `Error: "name" parameter is required.` }],
							details: { server: serverName, error: "missing_name" },
							isError: true,
						};
					}
					try {
						const result = await callTool(
							state,
							toolName,
							(params.arguments ?? {}) as Record<string, unknown>,
							signal,
						);
						const content = mcpResultToPiContent((result.content ?? []) as McpContentBlock[]);
						const details: Record<string, unknown> = {
							server: serverName,
							tool: toolName,
							isError: Boolean(result.isError),
						};
						if (result.structuredContent !== undefined) {
							details.structuredContent = result.structuredContent;
						}
						return {
							content: content.length > 0 ? content : [{ type: "text" as const, text: "(empty result)" }],
							details,
						};
					} catch (err) {
						return mcpErrorResult(err, serverName, toolName);
					}
				},
			});
		}

		if (isValidToolName(resourcesName)) {
			pi.registerTool({
				name: resourcesName,
				label: `MCP ${serverName}: resources`,
				description:
					`Read resources from the MCP server "${serverName}". ` +
					`Pass a "uri" to read a specific resource, or omit it to list available resources. ` +
					`If the server does not support resources, the list is empty.`,
				promptSnippet: `List or read resources on the ${serverName} MCP server`,
				parameters: Type.Object({
					uri: Type.Optional(
						Type.String({ description: "Resource URI to read; omit to list all resources" }),
					),
				}),
				async execute(_toolCallId, params, signal) {
					try {
						const uri = typeof params.uri === "string" && params.uri.length > 0 ? params.uri : undefined;
						if (uri) {
							const result = await readResource(state, uri, signal);
							const blocks = (result.contents ?? []) as Array<{
								text?: string;
								uri: string;
								mimeType?: string;
							}>;
							const text = blocks
								.map((b) => `[${b.uri}${b.mimeType ? ` (${b.mimeType})` : ""}]\n${b.text ?? ""}`)
								.join("\n\n");
							return {
								content: [{ type: "text" as const, text: text || "(empty resource)" }],
								details: { server: serverName, uri, contents: blocks },
							};
						}
						const resources = await listResources(state, signal);
						const lines = resources.map(
							(r) => `- ${r.name} (${r.uri})${r.description ? ` — ${r.description}` : ""}`,
						);
						return {
							content: [
								{
									type: "text" as const,
									text:
										resources.length > 0
											? `Resources on "${serverName}" (${resources.length}):\n\n${lines.join("\n")}`
											: `MCP server "${serverName}" exposes no resources.`,
								},
							],
							details: { server: serverName, resources },
						};
					} catch (err) {
						return mcpErrorResult(err, serverName, "resources");
					}
				},
			});
		}
	}

	// Update footer status to reflect the lazy-loaded state.
	pi.on("session_start", (_event, ctx) => {
		const names = Array.from(states.keys());
		ctx.ui.setStatus(
			"mcp",
			`MCP ${names.length} server${names.length === 1 ? "" : "s"}: ${names.join(", ")} (lazy)`,
		);
	});

	// Close all live clients on shutdown.
	pi.on("session_shutdown", async () => {
		await Promise.all(
			Array.from(states.values()).map(async (state) => {
				if (state.client) {
					try {
						await state.client.close();
					} catch (err) {
						console.warn(`[mcp] error closing "${state.name}":`, err);
					}
					state.client = null;
				}
			}),
		);
	});
}

function mcpErrorResult(err: unknown, server: string, tool: string): {
	content: Array<{ type: "text"; text: string }>;
	details: Record<string, unknown>;
	isError: true;
} {
	const message = err instanceof Error ? err.message : String(err);
	return {
		content: [{ type: "text" as const, text: `MCP error (${server}.${tool}): ${message}` }],
		details: { server, tool, error: message },
		isError: true,
	};
}
