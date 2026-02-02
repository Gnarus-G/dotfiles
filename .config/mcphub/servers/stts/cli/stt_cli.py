#!/usr/bin/env python3
"""CLI for Speech-to-Text operations."""

import sys
from pathlib import Path

import click

from stt import RunPodSTT


@click.command()
@click.argument("audio_file", type=click.Path(exists=True, path_type=Path))
@click.option(
    "--language",
    "-l",
    help="Language code for transcription (e.g., 'en', 'es')"
)
@click.option(
    "--model",
    "-m",
    default="base",
    help="Whisper model to use (tiny, base, small, medium, large-v1, etc.)"
)
@click.option(
    "--api-key",
    envvar="RUNPOD_API_KEY",
    help="RunPod API key (or set RUNPOD_API_KEY env var)"
)
@click.option(
    "--endpoint-id",
    envvar="RUNPOD_STT_ENDPOINT_ID",
    help="RunPod endpoint ID (or set RUNPOD_STT_ENDPOINT_ID env var)"
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output file to save transcription (default: stdout)"
)
def transcribe(
    audio_file: Path,
    language: str | None,
    model: str,
    api_key: str | None,
    endpoint_id: str | None,
    output: Path | None
):
    """Transcribe an audio file to text using RunPod STT.
    
    AUDIO_FILE: Path to the audio file to transcribe (WAV format)
    """
    try:
        # Initialize STT client
        stt = RunPodSTT(api_key=api_key, endpoint_id=endpoint_id)
        
        # Perform transcription
        click.echo(f"Transcribing {audio_file}...", err=True)
        result = stt.transcribe(audio_file, language=language, model=model)
        
        # Output result
        transcription = result.text
        
        if output:
            output.write_text(transcription)
            click.echo(f"Transcription saved to: {output}", err=True)
        else:
            click.echo(transcription)
        
        # Print metadata to stderr
        if result.language:
            click.echo(f"Detected language: {result.language}", err=True)
        
        return 0
        
    except FileNotFoundError as e:
        click.echo(f"Error: {e}", err=True)
        return 1
    except ValueError as e:
        click.echo(f"Error: {e}", err=True)
        return 1
    except RuntimeError as e:
        click.echo(f"Transcription failed: {e}", err=True)
        return 1


def main():
    """Entry point for the STT CLI."""
    transcribe()


if __name__ == "__main__":
    main()
