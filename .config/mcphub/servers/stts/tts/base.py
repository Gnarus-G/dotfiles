"""Abstract base class for Text-to-Speech operations."""

from abc import ABC, abstractmethod
from pathlib import Path
from dataclasses import dataclass
from typing import Optional


@dataclass
class SynthesisResult:
    """Result of a text-to-speech synthesis operation."""
    audio_path: Path
    duration_seconds: Optional[float] = None
    sample_rate: Optional[int] = None


class TextToSpeech(ABC):
    """Abstract base class for Text-to-Speech operations.
    
    Implementations should provide a synthesize method that converts
    text to audio files.
    """
    
    @abstractmethod
    def synthesize(
        self,
        text: str,
        output_path: Path,
        voice: Optional[str] = None,
        **kwargs
    ) -> SynthesisResult:
        """Synthesize text to speech and save to audio file.
        
        Args:
            text: Text to synthesize
            output_path: Path to save the audio file
            voice: Optional voice identifier
            **kwargs: Additional implementation-specific parameters
            
        Returns:
            SynthesisResult containing the path to the generated audio
            
        Raises:
            ValueError: If text is empty or invalid
            RuntimeError: If synthesis fails
        """
        pass
    
    def validate_output_path(self, output_path: Path) -> None:
        """Validate that the output directory exists.
        
        Args:
            output_path: Path to validate
            
        Raises:
            ValueError: If parent directory doesn't exist
        """
        parent = output_path.parent
        if parent and not parent.exists():
            raise ValueError(f"Output directory does not exist: {parent}")
