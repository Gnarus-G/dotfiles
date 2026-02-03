#!/usr/bin/env python3
"""CLI for Speech-to-Text operations."""

import sys
import tempfile
from pathlib import Path
from typing import Callable

import click

from stt import RunPodSTT
from stt.recorder import record_audio, LoopRecorder


@click.group()
def cli():
    """Speech-to-Text CLI - transcribe audio files or record from microphone."""
    pass


@cli.command(name="transcribe")
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
def transcribe_command(
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
        stt = RunPodSTT(api_key=api_key, endpoint_id=endpoint_id)
        click.echo(f"Transcribing {audio_file}...", err=True)
        result = stt.transcribe(audio_file, language=language, model=model)
        
        transcription = result.text
        
        if output:
            output.write_text(transcription)
            click.echo(f"Transcription saved to: {output}", err=True)
        else:
            click.echo(transcription)
        
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


@cli.command(name="record")
@click.option(
    "--duration",
    "-d",
    type=float,
    help="Record for a fixed duration in seconds"
)
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output file path (default: temp file, deleted after transcription)"
)
@click.option(
    "--no-transcribe",
    is_flag=True,
    help="Save recording without transcribing"
)
@click.option(
    "--loop",
    "-l",
    is_flag=True,
    help="Enable loop mode for continuous recording sessions"
)
@click.option(
    "--output-dir",
    type=click.Path(path_type=Path),
    help="Output directory for loop mode (default: current directory)"
)
@click.option(
    "--language",
    "-L",
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
def record_command(
    duration: float | None,
    output: Path | None,
    no_transcribe: bool,
    loop: bool,
    output_dir: Path | None,
    language: str | None,
    model: str,
    api_key: str | None,
    endpoint_id: str | None
):
    """Record audio from microphone and optionally transcribe.
    
    Examples:
    
        stt record                              # Record, transcribe, output text
        
        stt record -o meeting.wav              # Save to file
        
        stt record -d 60                         # Record for 60 seconds
        
        stt record -l                           # Continuous loop mode
        
        stt record -l --no-transcribe           # Loop, just record no transcription
    
    Controls:
    
    Single recording:
        Press ENTER to stop recording
        Ctrl+C to cancel
    
    Loop mode:
        ENTER = stop current, start next recording
        'q' + ENTER = quit loop
        Ctrl+C = emergency exit
    """
    try:
        if loop:
            # Loop mode
            if not output_dir:
                output_dir = Path.cwd()
            
            click.echo(f"🎤 Starting loop recording mode...")
            click.echo(f"   Output directory: {output_dir.absolute()}")
            
            # Setup transcription callback if needed
            def transcribe_func(audio_path: Path) -> str:
                stt = RunPodSTT(api_key=api_key, endpoint_id=endpoint_id)
                result = stt.transcribe(audio_path, language=language, model=model)
                return result.text
            
            transcribe_cb = transcribe_func if not no_transcribe else None
            
            loop_recorder = LoopRecorder(output_dir, transcribe_cb)
            sessions = loop_recorder.run()
            
            click.echo(f"\n✓ Complete! Recorded {len(sessions)} segments")
            for i, session in enumerate(sessions, 1):
                click.echo(f"   {i}. {session.audio_path.name} ({session.duration:.1f}s)")
            
        else:
            # Single recording mode
            temp_file = None
            if not output:
                if no_transcribe:
                    click.echo("Error: --output required when using --no-transcribe", err=True)
                    return 1
                # Create temp file that will be deleted after transcription
                temp_file = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
                output = Path(temp_file.name)
            
            session = record_audio(output, duration=duration)
            
            click.echo(f"\n✓ Recording complete: {session.duration:.1f} seconds")
            
            if not no_transcribe:
                click.echo("📝 Transcribing...", err=True)
                stt = RunPodSTT(api_key=api_key, endpoint_id=endpoint_id)
                result = stt.transcribe(session.audio_path, language=language, model=model)
                
                click.echo(result.text)
                
                if result.language:
                    click.echo(f"Detected language: {result.language}", err=True)
                
                # Clean up temp file
                if temp_file:
                    try:
                        session.audio_path.unlink()
                    except:
                        pass
            
        return 0
        
    except KeyboardInterrupt:
        click.echo("\n\n⚠️  Recording cancelled", err=True)
        return 130
    except RuntimeError as e:
        click.echo(f"Error: {e}", err=True)
        return 1
    except Exception as e:
        import traceback
        error_msg = str(e) if str(e) else f"{type(e).__name__}: {repr(e)}"
        click.echo(f"\nUnexpected error: {error_msg}", err=True)
        click.echo(f"Error type: {type(e).__name__}", err=True)
        click.echo("Traceback:", err=True)
        click.echo(traceback.format_exc(), err=True)
        return 1


def main():
    """Entry point for the STT CLI."""
    cli()


if __name__ == "__main__":
    main()
