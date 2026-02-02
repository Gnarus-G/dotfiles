#!/usr/bin/env python3
"""CLI for Text-to-Speech operations."""

import sys
from pathlib import Path

import click

from tts import RunPodTTS


@click.command()
@click.argument("text")
@click.argument("output_file", type=click.Path(path_type=Path))
@click.option(
    "--voice",
    "-v",
    help="Voice to use for synthesis"
)
@click.option(
    "--speed",
    "-s",
    default=1.0,
    type=float,
    help="Speech speed multiplier (default: 1.0)"
)
@click.option(
    "--api-key",
    envvar="RUNPOD_API_KEY",
    help="RunPod API key (or set RUNPOD_API_KEY env var)"
)
@click.option(
    "--endpoint-id",
    envvar="RUNPOD_TTS_ENDPOINT_ID",
    help="RunPod endpoint ID (or set RUNPOD_TTS_ENDPOINT_ID env var)"
)
@click.option(
    "--stdin",
    "-i",
    is_flag=True,
    help="Read text from stdin instead of command argument"
)
def synthesize(
    text: str,
    output_file: Path,
    voice: str | None,
    speed: float,
    api_key: str | None,
    endpoint_id: str | None,
    stdin: bool
):
    """Synthesize text to speech using RunPod TTS.
    
    TEXT: Text to synthesize (use --stdin to read from stdin instead)
    OUTPUT_FILE: Path to save the audio file (WAV format)
    """
    try:
        # Get text from stdin if requested
        if stdin:
            text = sys.stdin.read().strip()
            if not text:
                click.echo("Error: No text provided via stdin", err=True)
                return 1
        
        # Ensure output directory exists
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Initialize TTS client
        tts = RunPodTTS(api_key=api_key, endpoint_id=endpoint_id)
        
        # Perform synthesis
        click.echo(f"Synthesizing speech...", err=True)
        result = tts.synthesize(text, output_file, voice=voice, speed=speed)
        
        # Output result
        click.echo(f"Audio saved to: {result.audio_path}", err=True)
        
        if result.duration_seconds:
            click.echo(f"Duration: {result.duration_seconds:.2f}s", err=True)
        
        return 0
        
    except ValueError as e:
        click.echo(f"Error: {e}", err=True)
        return 1
    except RuntimeError as e:
        click.echo(f"Synthesis failed: {e}", err=True)
        return 1


def main():
    """Entry point for the TTS CLI."""
    synthesize()


if __name__ == "__main__":
    main()
