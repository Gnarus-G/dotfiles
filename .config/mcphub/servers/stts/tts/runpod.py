"""RunPod implementation of Text-to-Speech."""

import os
import base64
from pathlib import Path
from typing import Optional

import runpod

from .base import TextToSpeech, SynthesisResult


class RunPodTTS(TextToSpeech):
    """RunPod-based Text-to-Speech implementation.
    
    Uses RunPod serverless endpoints to synthesize speech from text.
    Requires RUNPOD_API_KEY and RUNPOD_TTS_ENDPOINT_ID environment variables.
    """
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        endpoint_id: Optional[str] = None
    ):
        """Initialize RunPod TTS client.
        
        Args:
            api_key: RunPod API key (defaults to RUNPOD_API_KEY env var)
            endpoint_id: RunPod endpoint ID (defaults to RUNPOD_TTS_ENDPOINT_ID env var)
            
        Raises:
            ValueError: If API key or endpoint ID is not provided
        """
        self.api_key = api_key or os.environ.get("RUNPOD_API_KEY")
        self.endpoint_id = endpoint_id or os.environ.get("RUNPOD_TTS_ENDPOINT_ID")
        
        if not self.api_key:
            raise ValueError(
                "RunPod API key required. Set RUNPOD_API_KEY environment variable "
                "or pass api_key parameter."
            )
        if not self.endpoint_id:
            raise ValueError(
                "RunPod endpoint ID required. Set RUNPOD_TTS_ENDPOINT_ID environment variable "
                "or pass endpoint_id parameter."
            )
        
        runpod.api_key = self.api_key
        self.endpoint = runpod.Endpoint(self.endpoint_id)
    
    def synthesize(
        self,
        text: str,
        output_path: Path,
        voice: Optional[str] = None,
        speed: float = 1.0,
        **kwargs
    ) -> SynthesisResult:
        """Synthesize text to speech using RunPod endpoint.
        
        Args:
            text: Text to synthesize into speech
            output_path: Path to save the WAV audio file
            voice: Optional voice identifier/speaker
            speed: Speech speed multiplier (default 1.0)
            **kwargs: Additional parameters passed to RunPod endpoint
            
        Returns:
            SynthesisResult with path to generated audio file
            
        Raises:
            ValueError: If text is empty
            RuntimeError: If synthesis fails
        """
        if not text:
            raise ValueError("Text cannot be empty")
        
        self.validate_output_path(output_path)
        
        # Prepare input for RunPod endpoint
        input_data = {
            "text": text,
            "speed": speed,
        }
        if voice:
            input_data["voice"] = voice
            input_data["speaker"] = voice
        
        # Add any additional parameters
        input_data.update(kwargs)
        
        try:
            # Run synthesis
            result = self.endpoint.run_sync({"input": input_data})
            
            if "error" in result:
                raise RuntimeError(f"Synthesis failed: {result['error']}")
            
            # Decode audio from base64
            audio_base64 = result.get("audio")
            if not audio_base64:
                raise RuntimeError("No audio data in response")
            
            audio_bytes = base64.b64decode(audio_base64)
            
            # Write audio to file
            with open(output_path, "wb") as f:
                f.write(audio_bytes)
            
            # Extract metadata if available
            duration = result.get("duration_seconds")
            sample_rate = result.get("sample_rate")
            
            return SynthesisResult(
                audio_path=output_path,
                duration_seconds=duration,
                sample_rate=sample_rate
            )
            
        except Exception as e:
            raise RuntimeError(f"Synthesis failed: {str(e)}") from e
