#!/usr/bin/env python3
"""
MCP Screenshot Server using KDE Spectacle
Provides screenshot capabilities via Model Context Protocol
"""

import subprocess
import tempfile
import base64
import json
import sys
from pathlib import Path

from mcp.server import Server
from mcp.types import TextContent, Tool

app = Server("screenshot-mcp")

SCREENS_DIR = Path.home() / ".local" / "share" / "screenshots"
SCREENS_DIR.mkdir(parents=True, exist_ok=True)


def run_spectacle(mode: str, delay_ms: int = 0) -> Path:
    """Run spectacle with given mode and return screenshot path."""
    timestamp = subprocess.run(
        ["date", "+%Y%m%d_%H%M%S"],
        capture_output=True,
        text=True
    ).stdout.strip()
    
    filename = f"screenshot_{timestamp}.png"
    output_path = SCREENS_DIR / filename
    
    cmd = ["spectacle", "-b", "-o", str(output_path)]
    
    if mode == "fullscreen":
        cmd.extend(["-f"])
    elif mode == "current":
        cmd.extend(["-m"])
    elif mode == "active":
        cmd.extend(["-a"])
    elif mode == "window":
        cmd.extend(["-u"])
    
    if delay_ms > 0:
        cmd.extend(["-d", str(delay_ms)])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise RuntimeError(f"Spectacle failed: {result.stderr}")
    
    return output_path


def encode_image_to_base64(path: Path) -> str:
    """Encode image file to base64 string."""
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="take_screenshot",
            description="Capture a screenshot of the desktop/monitor/window",
            inputSchema={
                "type": "object",
                "properties": {
                    "mode": {
                        "type": "string",
                        "enum": ["fullscreen", "current", "active", "window"],
                        "description": "Screenshot mode: fullscreen (entire desktop), current (current monitor), active (active window), window (window under cursor)"
                    },
                    "delay": {
                        "type": "integer",
                        "description": "Delay before taking screenshot in milliseconds",
                        "default": 0
                    },
                    "include_base64": {
                        "type": "boolean",
                        "description": "Whether to include base64-encoded image data in response",
                        "default": True
                    }
                },
                "required": ["mode"]
            }
        ),
        Tool(
            name="list_screenshots",
            description="List all saved screenshots",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "take_screenshot":
        mode = arguments.get("mode", "fullscreen")
        delay = arguments.get("delay", 0)
        include_base64 = arguments.get("include_base64", True)
        
        try:
            screenshot_path = run_spectacle(mode, delay)
            
            response = {
                "success": True,
                "path": str(screenshot_path),
                "mode": mode,
                "filename": screenshot_path.name
            }
            
            if include_base64:
                response["base64"] = encode_image_to_base64(screenshot_path)
            
            return [TextContent(
                type="text",
                text=json.dumps(response, indent=2)
            )]
        
        except Exception as e:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "success": False,
                    "error": str(e)
                })
            )]
    
    elif name == "list_screenshots":
        screenshots = sorted(SCREENS_DIR.glob("*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
        
        files = []
        for s in screenshots:
            stat = s.stat()
            files.append({
                "filename": s.name,
                "path": str(s),
                "size_bytes": stat.st_size,
                "modified": stat.st_mtime
            })
        
        return [TextContent(
            type="text",
            text=json.dumps({
                "count": len(files),
                "directory": str(SCREENS_DIR),
                "screenshots": files[:50]  # Limit to 50 most recent
            }, indent=2)
        )]
    
    else:
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Unknown tool: {name}"})
        )]


async def main():
    from mcp.server.stdio import stdio_server
    
    async with stdio_server() as streams:
        await app.run(
            streams[0],
            streams[1],
            app.create_initialization_options()
        )


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
