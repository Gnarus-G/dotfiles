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
 *   - mcp_list_servers          -> list configured MCP servers
 *   - mcp_list_tools(server)    -> list tools exposed by one server
 *   - mcp_call(server, name, arguments) -> forwards to one server tool
 *   - mcp_resources(server, uri?) -> list/read resources from one server
 *
 * The model gets a fixed, predictable surface regardless of how many MCP
 * servers or server tools are configured. Discovery happens once on first
 * call per server; the result is cached for the rest of the session.
 *
 * Lazy by design: startup only reads config and registers dispatcher tools.
 * MCP server processes are not spawned until the first server-specific MCP
 * call, so pi startup is unaffected by MCP cost (e.g. `npx -y` downloads).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import type { Tool as McpTool } from "@modelcontextprotocol/sdk/types.js";
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

interface McpResource {
	uri: string;
	name: string;
	description?: string;
	mimeType?: string;
}

interface ServerState {
	name: string;
	config: ServerConfig;
	connectPromise: Promise<Client> | null;
	client: Client | null;
	tools: McpTool[] | null;
	resources: McpResource[] | null;
}

function newServerState(name: string, config: ServerConfig): ServerState {
	return { name, config, connectPromise: null, client: null, tools: null, resources: null };
}

async function ensureConnected(state: ServerState, signal?: AbortSignal): Promise<Client> {
	if (state.client) return state.client;
	if (state.connectPromise) return state.connectPromise;

	state.connectPromise = (async () => {
		const client = new Client({ name: "pi", version: "0.1.0" }, { capabilities: {} });
		state.client = client;
		const transport = new StdioClientTransport({
			command: state.config.command,
			args: state.config.args ?? [],
			env: state.config.env,
		});
		await client.connect(transport, signal ? { signal } : undefined);
		state.connectPromise = null;
		return client;
	})().catch((err) => {
		state.client = null;
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

async function listResources(state: ServerState, signal?: AbortSignal): Promise<McpResource[]> {
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
		return state.resources;
	} catch (err) {
		if (isUnsupportedResourcesError(err)) {
			state.resources = [];
			return state.resources;
		}
		throw err;
	}
}

function isUnsupportedResourcesError(err: unknown): boolean {
	const message = err instanceof Error ? err.message.toLowerCase() : String(err).toLowerCase();
	return message.includes("method not found") || message.includes("not implemented") || message.includes("unsupported");
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

function formatServerList(states: Map<string, ServerState>): string {
	return Array.from(states.values())
		.map((state) => `- ${state.name}: ${state.config.command}${state.config.args?.length ? ` ${state.config.args.join(" ")}` : ""}`)
		.join("\n");
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

	function getState(serverName: string) {
		const state = states.get(serverName);
		if (state) return state;
		return undefined;
	}

	function missingServerResult(serverName: string) {
		return {
			content: [{ type: "text" as const, text: `Unknown MCP server "${serverName}". Available servers:\n\n${formatServerList(states)}` }],
			details: { server: serverName, availableServers: Array.from(states.keys()), error: "unknown_server" },
			isError: true as const,
		};
	}

	pi.registerTool({
		name: "mcp_list_servers",
		label: "MCP: list servers",
		description: "List configured MCP servers available through the Pi MCP extension.",
		promptSnippet: "List configured MCP servers",
		parameters: Type.Object({}),
		async execute() {
			const serverNames = Array.from(states.keys());
			return {
				content: [{ type: "text" as const, text: `MCP servers (${serverNames.length}):\n\n${formatServerList(states)}` }],
				details: { servers: serverNames },
			};
		},
	});

	pi.registerTool({
		name: "mcp_list_tools",
		label: "MCP: list tools",
		description:
			"List tools exposed by a configured MCP server. " +
			"Returns tool names, descriptions, and JSON-Schema input schemas. " +
			"Call this before mcp_call when you need to discover names or argument shapes.",
		promptSnippet: "Discover tools on a configured MCP server",
		promptGuidelines: [
			"Use mcp_list_servers to discover available MCP server names when you are unsure which server to use.",
			"Use mcp_list_tools before mcp_call when you need to know what tools an MCP server exposes or what their argument shapes are.",
		],
		parameters: Type.Object({
			server: Type.String({ description: "Configured MCP server name" }),
		}),
		async execute(_toolCallId, params, signal) {
			const serverName = String(params.server ?? "").trim();
			const state = getState(serverName);
			if (!state) return missingServerResult(serverName);
			try {
				const tools = await listTools(state, signal);
				return {
					content: [{ type: "text" as const, text: `Tools on MCP server "${serverName}" (${tools.length}):\n\n${formatToolList(tools)}` }],
					details: { server: serverName, tools: tools.map(formatToolForDiscovery) },
				};
			} catch (err) {
				return mcpErrorResult(err, serverName, "list_tools");
			}
		},
	});

	pi.registerTool({
		name: "mcp_call",
		label: "MCP: call tool",
		description:
			"Invoke a tool on a configured MCP server. " +
			"Pass the server name, tool name, and an arguments object matching the MCP tool inputSchema " +
			"(use mcp_list_tools to discover them).",
		promptSnippet: "Call a tool on a configured MCP server",
		promptGuidelines: [
			"Before calling mcp_call, prefer mcp_list_tools if you are unsure of the MCP tool's exact name or argument shape.",
		],
		parameters: Type.Object({
			server: Type.String({ description: "Configured MCP server name" }),
			name: Type.String({ description: "Name of the tool on the MCP server" }),
			arguments: Type.Optional(
				Type.Record(Type.String(), Type.Unknown(), {
					description: "Arguments matching the MCP tool's inputSchema",
				}),
			),
		}),
		async execute(_toolCallId, params, signal) {
			const serverName = String(params.server ?? "").trim();
			const toolName = String(params.name ?? "").trim();
			const state = getState(serverName);
			if (!state) return missingServerResult(serverName);
			if (!toolName) {
				return {
					content: [{ type: "text" as const, text: `Error: "name" parameter is required.` }],
					details: { server: serverName, error: "missing_name" },
					isError: true as const,
				};
			}
			try {
				const result = await callTool(state, toolName, (params.arguments ?? {}) as Record<string, unknown>, signal);
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
					isError: Boolean(result.isError),
				};
			} catch (err) {
				return mcpErrorResult(err, serverName, toolName);
			}
		},
	});

	pi.registerTool({
		name: "mcp_resources",
		label: "MCP: resources",
		description:
			"Read resources from a configured MCP server. " +
			"Pass a uri to read a specific resource, or omit uri to list available resources. " +
			"If the server does not support resources, the list is empty.",
		promptSnippet: "List or read resources on a configured MCP server",
		parameters: Type.Object({
			server: Type.String({ description: "Configured MCP server name" }),
			uri: Type.Optional(Type.String({ description: "Resource URI to read; omit to list all resources" })),
		}),
		async execute(_toolCallId, params, signal) {
			const serverName = String(params.server ?? "").trim();
			const state = getState(serverName);
			if (!state) return missingServerResult(serverName);
			try {
				const uri = typeof params.uri === "string" && params.uri.length > 0 ? params.uri : undefined;
				if (uri) {
					const result = await readResource(state, uri, signal);
					const blocks = (result.contents ?? []) as Array<{ text?: string; uri: string; mimeType?: string }>;
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
							text: resources.length > 0
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
				try {
					if (state.connectPromise) await state.connectPromise;
					if (state.client) await state.client.close();
				} catch (err) {
					console.warn(`[mcp] error closing "${state.name}":`, err);
				} finally {
					state.client = null;
					state.connectPromise = null;
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
