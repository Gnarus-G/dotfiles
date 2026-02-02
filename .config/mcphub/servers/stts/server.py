#!/usr/bin/env python3
"""MCP Server for STTS - Speech-to-Text and Text-to-Speech."""

import base64
import json
from pathlib import Path

from mcp.server import Server
from mcp.types import TextContent, Tool

from stt import RunPodSTT
from tts import RunPodTTS

app = Server("stts-mcp")


def get_stt_client() -> RunPodSTT:
    """Initialize RunPod STT client from environment."""
    return RunPodSTT()


def get_tts_client() -> RunPodTTS:
    """Initialize RunPod TTS client from environment."""
    return RunPodTTS()


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available STT and TTS tools."""
    return [
        Tool(
            name="transcribe_audio",
            description="Transcribe an audio file to text using RunPod speech-to-text",
            inputSchema={
                "type": "object",
                "properties": {
                    "audio_base64": {
                        "type": "string",
                        "description": "Base64-encoded audio file content (WAV format)"
                    },
                    "audio_path": {
                        "type": "string",
                        "description": "Path to local audio file (alternative to audio_base64)"
                    },
                    "language": {
                        "type": "string",
                        "description": "Language code (e.g., 'en', 'es'). Auto-detected if not provided."
                    },
                    "model": {
                        "type": "string",
                        "description": "Whisper model to use",
                        "enum": ["tiny", "base", "small", "medium", "large-v1", "large-v2", "large-v3", "turbo"],
                        "default": "base"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="synthesize_speech",
            description="Synthesize text to speech using RunPod text-to-speech",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "Text to synthesize into speech"
                    },
                    "voice": {
                        "type": "string",
                        "description": "Voice/speaker to use for synthesis"
                    },
                    "speed": {
                        "type": "number",
                        "description": "Speech speed multiplier",
                        "default": 1.0
                    },
                    "return_base64": {
                        "type": "boolean",
                        "description": "Whether to return audio as base64 string",
                        "default": True
                    },
                    "output_path": {
                        "type": "string",
                        "description": "Path to save audio file (if not returning base64)"
                    }
                },
                "required": ["text"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Handle tool calls for STT and TTS operations."""
    
    if name == "transcribe_audio":
        return await handle_transcribe(arguments)
    elif name == "synthesize_speech":
        return await handle_synthesize(arguments)
    else:
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Unknown tool: {name}"})
        )]


async def handle_transcribe(arguments: dict) -> list[TextContent]:
    """Handle audio transcription request."""
    audio_base64 = arguments.get("audio_base64")
    audio_path = arguments.get("audio_path")
    language = arguments.get("language")
    model = arguments.get("model", "base")
    
    try:
        # Validate input
        if not audio_base64 and not audio_path:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "success": False,
                    "error": "Either audio_base64 or audio_path must be provided"
                })
            )]
        
        # Initialize STT client
        stt = get_stt_client()
        
        # Handle audio input
        if audio_base64:
            # Decode base64 and save to temp file
            import tempfile
            audio_bytes = base64.b64decode(audio_base64)
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                tmp.write(audio_bytes)
                tmp_path = Path(tmp.name)
        else:
            tmp_path = Path(audio_path)
        
        # Perform transcription
        result = stt.transcribe(tmp_path, language=language, model=model)
        
        # Cleanup temp file if we created one
        if audio_base64:
            tmp_path.unlink()
        
        response = {
            "success": True,
            "transcription": result.text,
            "language": result.language,
            "segments": result.segments
        }
        
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


async def handle_synthesize(arguments: dict) -> list[TextContent]:
    """Handle speech synthesis request."""
    text = arguments.get("text")
    voice = arguments.get("voice")
    speed = arguments.get("speed", 1.0)
    return_base64 = arguments.get("return_base64", True)
    output_path = arguments.get("output_path")
    
    try:
        # Validate input
        if not text:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "success": False,
                    "error": "Text is required"
                })
            )]
        
        # Initialize TTS client
        tts = get_tts_client()
        
        # Determine output path
        if output_path:
            audio_path = Path(output_path)
        else:
            import tempfile
            audio_path = Path(tempfile.mktemp(suffix=".wav"))
        
        # Perform synthesis
        result = tts.synthesize(text, audio_path, voice=voice, speed=speed)
        
        response = {
            "success": True,
            "audio_path": str(result.audio_path),
            "duration_seconds": result.duration_seconds,
            "sample_rate": result.sample_rate
        }
        
        # Include base64 audio if requested
        if return_base64:
            with open(result.audio_path, "rb") as f:
                audio_bytes = f.read()
            response["audio_base64"] = base64.b64encode(audio_bytes).decode("utf-8")
        
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


async def main():
    """Run the MCP server."""
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
