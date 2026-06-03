import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const PYTHON = String.raw`
import json
import os
import sys

if "OLLAMA_API_KEY" not in os.environ and "OLLAMA_WEBSEARCH_API_KEY" in os.environ:
    os.environ["OLLAMA_API_KEY"] = os.environ["OLLAMA_WEBSEARCH_API_KEY"]

from ollama import Client

kind = sys.argv[1]
payload = json.loads(sys.argv[2])
client = Client()

if kind == "web_search":
    result = client.web_search(
        query=payload["query"],
        max_results=int(payload.get("max_results", 3)),
    )
elif kind == "web_fetch":
    result = client.web_fetch(url=payload["url"])
else:
    raise SystemExit(f"unknown tool kind: {kind}")

if hasattr(result, "model_dump"):
    print(json.dumps(result.model_dump(), ensure_ascii=False))
else:
    print(json.dumps(result, ensure_ascii=False))
`;

async function callOllama(pi: ExtensionAPI, kind: "web_search" | "web_fetch", payload: unknown) {
	const result = await pi.exec(
		"uv",
		["run", "--quiet", "--with", "ollama", "python", "-c", PYTHON, kind, JSON.stringify(payload)],
		{ timeout: 30000 },
	);

	if (result.code !== 0) {
		throw new Error((result.stderr || result.stdout || `uv exited ${result.code}`).trim());
	}

	try {
		return JSON.parse(result.stdout);
	} catch {
		return { output: result.stdout.trim() };
	}
}

function pretty(data: unknown) {
	return JSON.stringify(data, null, 2);
}

export default function ollamaWebSearchExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description: "Search the web using Ollama Cloud's hosted web_search API.",
		promptSnippet: "Search the web through Ollama Cloud",
		promptGuidelines: [
			"Use web_search when current web information would help answer the user's question.",
			"After web_search returns relevant URLs, use web_fetch when page contents are needed before making specific claims.",
		],
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			max_results: Type.Optional(Type.Number({ description: "Maximum search results; default 3" })),
		}),
		async execute(_toolCallId, params) {
			const data = await callOllama(pi, "web_search", {
				query: params.query,
				max_results: params.max_results ?? 3,
			});

			return {
				content: [{ type: "text", text: pretty(data) }],
				details: data,
			};
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description: "Fetch a web page using Ollama Cloud's hosted web_fetch API.",
		promptSnippet: "Fetch web page contents through Ollama Cloud",
		promptGuidelines: [
			"Use web_fetch to inspect a specific URL before summarizing it or relying on page-specific details.",
		],
		parameters: Type.Object({
			url: Type.String({ description: "Absolute URL to fetch" }),
		}),
		async execute(_toolCallId, params) {
			const data = await callOllama(pi, "web_fetch", { url: params.url });

			return {
				content: [{ type: "text", text: pretty(data) }],
				details: data,
			};
		},
	});
}
