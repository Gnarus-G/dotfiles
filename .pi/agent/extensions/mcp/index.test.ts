import test from "node:test";
import assert from "node:assert/strict";
import mcpExtension from "./index.ts";

function createFakePi() {
	const tools: Array<{ name: string }> = [];
	const handlers: Record<string, unknown[]> = {};
	return {
		tools,
		pi: {
			registerTool(tool: { name: string }) {
				tools.push(tool);
			},
			on(event: string, handler: unknown) {
				(handlers[event] ??= []).push(handler);
			},
		},
	};
}

test("registers one fixed MCP tool surface instead of per-server generated tools", () => {
	const { pi, tools } = createFakePi();

	mcpExtension(pi as never);

	assert.deepEqual(
		tools.map((tool) => tool.name).sort(),
		["mcp_call", "mcp_list_servers", "mcp_list_tools", "mcp_resources"],
	);
});
