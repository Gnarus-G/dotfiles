"""Abstract base class for Speech-to-Text operations."""

from abc import ABC, abstractmethod
from pathlib import Path
from dataclasses import dataclass
from typing import Optional


@dataclass
class TranscriptionResult:
    """Result of a transcription operation."""
    text: str
    language: Optional[str] = None
    confidence: Optional[float] = None
    segments: Optional[list] = None


class SpeechToText(ABC):
    """Abstract base class for Speech-to-Text operations.
    
    Implementations should provide a transcribe method that converts
    audio files to text.
    """
    
    @abstractmethod
    def transcribe(
        self,
        audio_path: Path,
        language: Optional[str] = None,
        **kwargs
    ) -> TranscriptionResult:
        """Transcribe an audio file to text.
        
        Args:
            audio_path: Path to the audio file
            language: Optional language code (e.g., 'en', 'es')
            **kwargs: Additional implementation-specific parameters
            
        Returns:
            TranscriptionResult containing the transcribed text and metadata
            
        Raises:
            FileNotFoundError: If audio file doesn't exist
            ValueError: If audio format is not supported
            RuntimeError: If transcription fails
        """
        pass
    
    def validate_audio_file(self, audio_path: Path) -> None:
        """Validate that the audio file exists and is readable.
        
        Args:
            audio_path: Path to validate
            
        Raises:
            FileNotFoundError: If file doesn't exist
            ValueError: If path is not a file
        """
        if not audio_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        if not audio_path.is_file():
            raise ValueError(f"Path is not a file: {audio_path}")
