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
        
        try:
            # Run transcription
            result = self.endpoint.run_sync({"input": input_data})
            
            if "error" in result:
                raise RuntimeError(f"Transcription failed: {result['error']}")
            
            # Extract transcription from result
            # RunPod faster-whisper endpoint returns specific format
            transcription = result.get("transcription", "")
            detected_language = result.get("detected_language")
            segments = result.get("segments", [])
            
            return TranscriptionResult(
                text=transcription,
                language=detected_language or language,
                segments=segments
            )
            
        except Exception as e:
            raise RuntimeError(f"Transcription failed: {str(e)}") from e
