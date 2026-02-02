"""Text-to-Speech library."""

from .base import TextToSpeech
from .runpod import RunPodTTS

__all__ = ["TextToSpeech", "RunPodTTS"]
