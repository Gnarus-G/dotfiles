# STTS - Speech-to-Text and Text-to-Speech

A Python library and MCP server for speech operations using RunPod serverless endpoints.

## Features

- **Speech-to-Text (STT)**: Transcribe audio files to text using RunPod's Whisper endpoints
- **Text-to-Speech (TTS)**: Synthesize text into speech using RunPod TTS endpoints
- **MCP Server**: Expose STT/TTS capabilities via Model Context Protocol
- **CLI Tools**: Command-line interfaces for both operations
- **Abstract Interfaces**: Easy to implement alternative providers

## Installation

```bash
# Using uv (recommended)
cd /home/gnarus/d/dotfiles/.config/mcphub/servers/stts
uv pip install -e .

# Or using pip
pip install -e .
```

## Configuration

Set the following environment variables:

```bash
export RUNPOD_API_KEY="your-runpod-api-key"
export RUNPOD_STT_ENDPOINT_ID="your-stt-endpoint-id"
export RUNPOD_TTS_ENDPOINT_ID="your-tts-endpoint-id"
```

## CLI Usage

### Speech-to-Text

```bash
# Transcribe an audio file
stt /path/to/audio.wav

# Specify language and model
stt /path/to/audio.wav --language en --model turbo

# Save to file
stt /path/to/audio.wav --output transcription.txt
```

### Text-to-Speech

```bash
# Synthesize text to audio
tts "Hello, world!" /path/to/output.wav

# Use stdin
echo "Hello, world!" | tts - /path/to/output.wav --stdin

# Specify voice and speed
tts "Hello, world!" /path/to/output.wav --voice speaker_0 --speed 1.2
```

## Library Usage

### Speech-to-Text

```python
from stts.stt import RunPodSTT
from pathlib import Path

stt = RunPodSTT()
result = stt.transcribe(Path("audio.wav"), language="en")
print(result.text)
```

### Text-to-Speech

```python
from stts.tts import RunPodTTS
from pathlib import Path

tts = RunPodTTS()
result = tts.synthesize("Hello, world!", Path("output.wav"))
print(f"Audio saved to: {result.audio_path}")
```

## MCP Server

The MCP server provides two tools:

- `transcribe_audio`: Transcribe audio (base64 or file path)
- `synthesize_speech`: Generate speech from text (returns base64 audio)

### Running the Server

```bash
stts-server
```

Or with uv:

```bash
uv run python -m stts.server
```

### MCP Configuration

Add to your MCPHub `servers.json`:

```json
{
  "mcpServers": {
    "stts": {
      "command": "uv",
      "args": [
        "run",
        "--project",
        "${HOME}/.config/mcphub/servers/stts",
        "python",
        "-m",
        "stts.server"
      ],
      "autoApprove": ["transcribe_audio", "synthesize_speech"],
      "env": {
        "RUNPOD_API_KEY": "${RUNPOD_API_KEY}",
        "RUNPOD_STT_ENDPOINT_ID": "${RUNPOD_STT_ENDPOINT_ID}",
        "RUNPOD_TTS_ENDPOINT_ID": "${RUNPOD_TTS_ENDPOINT_ID}"
      }
    }
  }
}
```

## Architecture

```
stts/
├── stt/
│   ├── base.py      # Abstract STT interface
│   └── runpod.py    # RunPod implementation
├── tts/
│   ├── base.py      # Abstract TTS interface
│   └── runpod.py    # RunPod implementation
├── cli/
│   ├── stt_cli.py   # STT CLI
│   └── tts_cli.py   # TTS CLI
└── server.py        # MCP server
```

## Extending

To add a new STT provider:

```python
from stts.stt.base import SpeechToText, TranscriptionResult

class MySTT(SpeechToText):
    def transcribe(self, audio_path, language=None, **kwargs):
        # Implementation
        return TranscriptionResult(text="transcribed text")
```

## License

MIT
