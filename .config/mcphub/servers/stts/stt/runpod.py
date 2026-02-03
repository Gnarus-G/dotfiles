"""RunPod implementation of Speech-to-Text."""

import os
import base64
from pathlib import Path
from typing import Optional

import runpod

from .base import SpeechToText, TranscriptionResult


class RunPodSTT(SpeechToText):
    """RunPod-based Speech-to-Text implementation.
    
    Uses RunPod serverless endpoints to transcribe audio files.
    Requires RUNPOD_API_KEY and RUNPOD_STT_ENDPOINT_ID environment variables.
    """
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        endpoint_id: Optional[str] = None
    ):
        """Initialize RunPod STT client.
        
        Args:
            api_key: RunPod API key (defaults to RUNPOD_API_KEY env var)
            endpoint_id: RunPod endpoint ID (defaults to RUNPOD_STT_ENDPOINT_ID env var)
            
        Raises:
            ValueError: If API key or endpoint ID is not provided
        """
        self.api_key = api_key or os.environ.get("RUNPOD_API_KEY")
        self.endpoint_id = endpoint_id or os.environ.get("RUNPOD_STT_ENDPOINT_ID")
        
        if not self.api_key:
            raise ValueError(
                "RunPod API key required. Set RUNPOD_API_KEY environment variable "
                "or pass api_key parameter."
            )
        if not self.endpoint_id:
            raise ValueError(
                "RunPod endpoint ID required. Set RUNPOD_STT_ENDPOINT_ID environment variable "
                "or pass endpoint_id parameter."
            )
        
        runpod.api_key = self.api_key
        self.endpoint = runpod.Endpoint(self.endpoint_id)
    
    def transcribe(
        self,
        audio_path: Path,
        language: Optional[str] = None,
        model: str = "base",
        **kwargs
    ) -> TranscriptionResult:
        """Transcribe audio file using RunPod endpoint.
        
        Args:
            audio_path: Path to the audio file (WAV format)
            language: Optional language code for transcription
            model: Whisper model to use (tiny, base, small, medium, large-v1, etc.)
            **kwargs: Additional parameters passed to RunPod endpoint
            
        Returns:
            TranscriptionResult with transcribed text
            
        Raises:
            FileNotFoundError: If audio file doesn't exist
            RuntimeError: If transcription fails
        """
        self.validate_audio_file(audio_path)
        
        # Read and encode audio file
        with open(audio_path, "rb") as f:
            audio_bytes = f.read()
        audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
        
        # Prepare input for RunPod endpoint
        input_data = {
            "audio_base64": audio_base64,
            "model": model,
        }
        if language:
            input_data["language"] = language
        
        # Add any additional parameters
        input_data.update(kwargs)
        
        # Retry logic for cold-starting serverless endpoints
        max_retries = 3
        retry_delay = 10  # seconds
        
        for attempt in range(max_retries):
            try:
                # Run transcription
                result = self.endpoint.run_sync({"input": input_data})
                
                # Handle None or empty response (cold start scenario)
                if not result:
                    if attempt < max_retries - 1:
                        import time
                        print(f"  Endpoint cold-starting, waiting {retry_delay}s... (attempt {attempt + 1}/{max_retries})")
                        time.sleep(retry_delay)
                        retry_delay *= 2  # Exponential backoff
                        continue
                    raise RuntimeError(
                        "Transcription failed: No response from RunPod endpoint after retries. "
                        "The endpoint may be offline or the audio file may be too large. "
                        f"Endpoint ID: {self.endpoint_id}"
                    )
                
                # Handle explicit error in response
                if "error" in result:
                    error_msg = result["error"]
                    raise RuntimeError(
                        f"Transcription failed: {error_msg}. "
                        f"Check endpoint logs for details. Endpoint ID: {self.endpoint_id}"
                    )
                
                # Extract transcription from result
                # RunPod faster-whisper endpoint returns specific format
                transcription = result.get("transcription", "")
                detected_language = result.get("detected_language")
                segments = result.get("segments", [])
                
                # Handle empty transcription
                if not transcription and not segments:
                    raise RuntimeError(
                        "Transcription failed: Empty response from endpoint. "
                        "The audio may be silent or the endpoint format may have changed. "
                        f"Response keys: {list(result.keys())}"
                    )
                
                return TranscriptionResult(
                    text=transcription,
                    language=detected_language or language,
                    segments=segments
                )
                
            except RuntimeError:
                # Re-raise runtime errors immediately (don't retry actual failures)
                raise
            except Exception as e:
                if attempt < max_retries - 1:
                    import time
                    print(f"  Transcription error, retrying in {retry_delay}s... (attempt {attempt + 1}/{max_retries})")
                    time.sleep(retry_delay)
                    retry_delay *= 2
                    continue
                raise RuntimeError(f"Transcription failed after {max_retries} attempts: {str(e)}") from e
        
        # Should never reach here
        raise RuntimeError("Transcription failed: Exceeded maximum retry attempts")
