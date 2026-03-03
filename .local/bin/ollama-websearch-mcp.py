# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "mcp",
#   "rich",
#   "ollama",
# ]
# ///
"""
MCP stdio server exposing Ollama web_search and web_fetch as tools.

Environment:
- OLLAMA_API_KEY (required): if set, will be used as Authorization header.
"""

from __future__ import annotations

import asyncio
import logging
import os
from typing import Any, Dict

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("ollama-websearch-mcp")

from ollama import Client

try:
  from mcp.server.fastmcp import FastMCP

  _FASTMCP_AVAILABLE = True
except Exception:
  _FASTMCP_AVAILABLE = False

if not _FASTMCP_AVAILABLE:
  from mcp.server import Server
  from mcp.server.stdio import stdio_server


if "OLLAMA_API_KEY" not in os.environ and "OLLAMA_WEBSEARCH_API_KEY" in os.environ:
  log.info("Using OLLAMA_WEBSEARCH_API_KEY as OLLAMA_API_KEY")
  os.environ["OLLAMA_API_KEY"] = os.environ["OLLAMA_WEBSEARCH_API_KEY"]

client = Client()
log.info("Ollama client initialized")


def _web_search_impl(query: str, max_results: int = 3) -> Dict[str, Any]:
  log.info("web_search query=%r max_results=%d", query, max_results)
  res = client.web_search(query=query, max_results=max_results)
  data = res.model_dump()
  log.debug("web_search result keys=%s", list(data.keys()))
  return data


def _web_fetch_impl(url: str) -> Dict[str, Any]:
  log.info("web_fetch url=%r", url)
  res = client.web_fetch(url=url)
  data = res.model_dump()
  log.debug("web_fetch result keys=%s", list(data.keys()))
  return data


if _FASTMCP_AVAILABLE:
  log.info("Using FastMCP backend")
  app = FastMCP('ollama-search-fetch')

  @app.tool()
  def web_search(query: str, max_results: int = 3) -> Dict[str, Any]:
    """
    Perform a web search using Ollama's hosted search API.

    Args:
      query: The search query to run.
      max_results: Maximum results to return (default: 3).

    Returns:
      JSON-serializable dict matching ollama.WebSearchResponse.model_dump()
    """

    return _web_search_impl(query=query, max_results=max_results)

  @app.tool()
  def web_fetch(url: str) -> Dict[str, Any]:
    """
    Fetch the content of a web page for the provided URL.

    Args:
      url: The absolute URL to fetch.

    Returns:
      JSON-serializable dict matching ollama.WebFetchResponse.model_dump()
    """

    return _web_fetch_impl(url=url)

  if __name__ == '__main__':
    app.run()

else:
  log.info("Using low-level Server backend (FastMCP unavailable)")
  server = Server('ollama-search-fetch')

  @server.tool()
  async def web_search(query: str, max_results: int = 3) -> Dict[str, Any]:
    """
    Perform a web search using Ollama's hosted search API.

    Args:
      query: The search query to run.
      max_results: Maximum results to return (default: 3).
    """

    return await asyncio.to_thread(_web_search_impl, query, max_results)

  @server.tool()
  async def web_fetch(url: str) -> Dict[str, Any]:
    """
    Fetch the content of a web page for the provided URL.

    Args:
      url: The absolute URL to fetch.
    """

    return await asyncio.to_thread(_web_fetch_impl, url)

  async def _main() -> None:
    async with stdio_server() as (read, write):
      await server.run(read, write)

  if __name__ == '__main__':
    asyncio.run(_main())
