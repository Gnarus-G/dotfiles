"""Audio recording with Actor-based concurrency model."""

import sys
import os
import time
import queue
import select
import threading
import subprocess
from pathlib import Path
from typing import Callable, Optional, Union
from dataclasses import dataclass
from datetime import timedelta
from abc import ABC, abstractmethod

import sounddevice as sd
import numpy as np


# Actor Model Base Classes
@dataclass
class Message:
    """Base message type for actor communication."""
    pass


class Actor(ABC):
    """Base Actor class following FP principles."""
    
    def __init__(self):
        self._mailbox: queue.Queue[Message] = queue.Queue()
        self._running = False
        self._thread: Optional[threading.Thread] = None
    
    def send(self, msg: Message) -> None:
        """Send a message to this actor's mailbox."""
        self._mailbox.put(msg)
    
    def start(self) -> None:
        """Start the actor's message processing loop."""
        if not self._running:
            self._running = True
            self._thread = threading.Thread(target=self._run)
            self._thread.daemon = True
            self._thread.start()
    
    def stop(self) -> None:
        """Stop the actor gracefully."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
    
    def _run(self) -> None:
        """Main actor loop - processes messages sequentially."""
        while self._running:
            try:
                msg = self._mailbox.get(timeout=0.1)
                self.handle(msg)
            except queue.Empty:
                continue
    
    @abstractmethod
    def handle(self, msg: Message) -> None:
        """Handle incoming messages - subclasses implement this."""
        pass


# Recording Messages
@dataclass
class StartRecording(Message):
    """Start recording to specified path."""
    output_path: Path
    duration: Optional[float] = None


@dataclass
class StopRecording(Message):
    """Stop current recording."""
    pass


@dataclass
class MeterUpdate(Message):
    """Update meter display with current levels."""
    peak_db: float
    duration: float


@dataclass
class RecordingComplete(Message):
    """Recording finished successfully."""
    audio_path: Path
    duration: float


@dataclass
class RecordingError(Message):
    """Recording encountered an error."""
    error: str


@dataclass
class InputDetected(Message):
    """User pressed Enter to stop recording."""
    pass


# Result Types
@dataclass
class RecordingSession:
    """Result of a recording session."""
    audio_path: Path
    duration: float


class Ok:
    """Success result wrapper."""
    def __init__(self, value):
        self.value = value


class Err:
    """Error result wrapper."""
    def __init__(self, error):
        self.error = error


Result = Union[Ok, Err]


class RecorderActor(Actor):
    """Actor that manages audio recording state and coordination.
    
    This actor eliminates race conditions by:
    - Holding all state internally (ffmpeg process, meter, etc.)
    - Processing messages sequentially in a single thread
    - Providing clean state transitions (idle -> recording -> stopped)
    """
    
    def __init__(
        self,
        sample_rate: int = 44100,
        channels: int = 1,
        input_device: Optional[str] = None
    ):
        super().__init__()
        self.sample_rate = sample_rate
        self.channels = channels
        self.input_device = input_device
        
        # State (encapsulated, no external mutation)
        self._ffmpeg_process: Optional[subprocess.Popen] = None
        self._meter_actor: Optional['MeterActor'] = None
        self._output_path: Optional[Path] = None
        self._start_time: Optional[float] = None
        self._result_queue: queue.Queue[Result] = queue.Queue()
        
    def handle(self, msg: Message) -> None:
        """Process messages sequentially - no race conditions."""
        if isinstance(msg, StartRecording):
            self._handle_start(msg)
        elif isinstance(msg, StopRecording):
            self._handle_stop()
        elif isinstance(msg, InputDetected):
            self._handle_input_detected()
        elif isinstance(msg, RecordingComplete):
            self._result_queue.put(Ok(RecordingSession(
                audio_path=msg.audio_path,
                duration=msg.duration
            )))
        elif isinstance(msg, RecordingError):
            self._result_queue.put(Err(msg.error))
    
    def _handle_input_detected(self) -> None:
        """Handle user pressing Enter."""
        if self._ffmpeg_process is not None:
            self._handle_stop()
    
    def _run(self) -> None:
        """Main actor loop - processes messages and checks for input."""
        while self._running:
            # Check for messages
            try:
                msg = self._mailbox.get(timeout=0.05)
                self.handle(msg)
            except queue.Empty:
                pass
            
            # Check for user input (non-blocking)
            if self._ffmpeg_process is not None:
                try:
                    if select.select([sys.stdin], [], [], 0)[0]:
                        sys.stdin.read(1)  # Consume Enter key
                        self.send(InputDetected())
                except:
                    pass
    
    def _handle_start(self, msg: StartRecording) -> None:
        """Start recording - pure state transition."""
        if self._ffmpeg_process is not None:
            self.send(RecordingError("Already recording"))
            return
        
        self._output_path = msg.output_path
        self._start_time = time.time()
        
        # Build and start ffmpeg
        cmd = self._build_ffmpeg_cmd(msg.output_path, msg.duration)
        try:
            self._ffmpeg_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
        except Exception as e:
            self.send(RecordingError(f"Failed to start ffmpeg: {e}"))
            return
        
        # Start meter actor for visual feedback
        self._meter_actor = MeterActor(self)
        self._meter_actor.start()
        
        # Print recording status and prompt
        print(f"🎤 Recording to: {msg.output_path}")
        if msg.duration is None:
            print("Press ENTER to stop recording...")
    
    def _handle_stop(self) -> None:
        """Stop recording - coordinated shutdown."""
        duration = 0.0
        if self._start_time:
            duration = time.time() - self._start_time
        
        # Stop meter first (visual feedback)
        if self._meter_actor:
            self._meter_actor.stop()
            self._meter_actor = None
        
        # Stop ffmpeg process
        if self._ffmpeg_process:
            if self._ffmpeg_process.poll() is None:
                self._ffmpeg_process.terminate()
                try:
                    self._ffmpeg_process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    self._ffmpeg_process.kill()
                    self._ffmpeg_process.wait()
            self._ffmpeg_process = None
        
        # Clear status line
        sys.stdout.write("\r\033[K\n")
        sys.stdout.flush()
        
        # Signal completion
        if self._output_path:
            self.send(RecordingComplete(
                audio_path=self._output_path,
                duration=duration
            ))
            self._output_path = None
            self._start_time = None
    
    def _build_ffmpeg_cmd(self, output_path: Path, duration: Optional[float]) -> list:
        """Build ffmpeg command - pure function."""
        ffmpeg = self._detect_ffmpeg()
        if not ffmpeg:
            raise RuntimeError("ffmpeg not found. Please install ffmpeg.")
        
        cmd = [
            ffmpeg,
            "-f", "alsa" if os.name != "nt" else "dshow",
            "-i", "default" if not self.input_device else self.input_device,
            "-ar", str(self.sample_rate),
            "-ac", str(self.channels),
            "-c:a", "pcm_s16le",
            "-y",
            str(output_path)
        ]
        
        if sys.platform == "darwin":
            cmd[1:3] = ["-f", "avfoundation"]
            cmd[3] = ":0"
        
        if duration:
            cmd.insert(1, "-t")
            cmd.insert(2, str(duration))
        
        return cmd
    
    def _detect_ffmpeg(self) -> Optional[str]:
        """Find ffmpeg executable."""
        for cmd in ["ffmpeg", "avconv"]:
            result = subprocess.run(
                ["which", cmd],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return result.stdout.strip()
        return None
    
    def record(
        self,
        output_path: Path,
        duration: Optional[float] = None
    ) -> RecordingSession:
        """Blocking record method - sends message and waits for result.
        
        This is the imperative shell that interfaces with the pure actor core.
        """
        # Start recording
        self.send(StartRecording(output_path=output_path, duration=duration))
        
        if duration:
            # Wait for fixed duration
            time.sleep(duration + 1)
            self.send(StopRecording())
        # else: input detection is handled by Actor's _run loop
        
        # Wait for result
        result = self._result_queue.get(timeout=10)
        
        if isinstance(result, Err):
            raise RuntimeError(result.error)
        
        return result.value


class MeterActor(Actor):
    """Actor that displays real-time audio levels.
    
    Separates the visual feedback concern from recording logic.
    """
    
    def __init__(self, recorder: RecorderActor):
        super().__init__()
        self.recorder = recorder
        self.peak_db = -60.0
        self.duration = 0.0
        self.start_time = time.time()
        self._audio_thread: Optional[threading.Thread] = None
        self._stop_audio = threading.Event()
    
    def handle(self, msg: Message) -> None:
        """Handle meter update messages."""
        if isinstance(msg, MeterUpdate):
            self._render(msg.peak_db, msg.duration)
    
    def _render(self, peak_db: float, duration: float) -> None:
        """Render VU meter on a single line."""
        # Map dB to bar width
        normalized = max(0, min(1, (peak_db + 60) / 60))
        width = 20
        filled = int(normalized * width)
        
        # Color based on level
        if peak_db > -3:
            color = "\033[91m"
        elif peak_db > -12:
            color = "\033[93m"
        else:
            color = "\033[92m"
        
        reset = "\033[0m"
        bar = "█" * filled + "░" * (width - filled)
        
        td = timedelta(seconds=int(duration))
        duration_str = str(td)[2:] if duration < 3600 else str(td)
        
        line = f"\r\033[K{color}🔴 Recording{reset} [{color}{bar}{reset}] {peak_db:+.1f}dB | {duration_str}"
        sys.stdout.write(line)
        sys.stdout.flush()
    
    def start(self) -> None:
        """Start meter actor and audio monitoring."""
        super().start()
        # Start audio capture in separate thread
        self._audio_thread = threading.Thread(target=self._monitor_audio)
        self._audio_thread.daemon = True
        self._audio_thread.start()
    
    def stop(self) -> None:
        """Stop meter and cleanup - keep final frame visible."""
        self._stop_audio.set()
        if self._audio_thread:
            self._audio_thread.join(timeout=1)
        super().stop()
        # Move to new line, keeping final meter frame visible
        sys.stdout.write("\n")
        sys.stdout.flush()
    
    def _monitor_audio(self) -> None:
        """Monitor audio levels using sounddevice.
        
        Runs in separate thread but only sends messages to actor - no direct mutation.
        """
        def audio_callback(indata, frames, time_info, status):
            if status:
                return
            
            # Calculate RMS and convert to dB
            rms = np.sqrt(np.mean(indata**2))
            if rms > 0:
                db = 20 * np.log10(rms)
            else:
                db = -60.0
            
            # Update local state
            self.peak_db = max(db, self.peak_db - 2)
            self.duration = time.time() - self.start_time
            
            # Send update message to self (actor pattern)
            self.send(MeterUpdate(peak_db=self.peak_db, duration=self.duration))
        
        try:
            with sd.InputStream(
                samplerate=44100,
                blocksize=1024,
                dtype=np.float32,
                channels=1,
                callback=audio_callback
            ):
                while not self._stop_audio.is_set():
                    time.sleep(0.1)
        except Exception:
            pass


def record_audio(
    output_path: Path,
    duration: Optional[float] = None
) -> RecordingSession:
    """Convenience function for recording.
    
    Pure wrapper that creates actor, records, returns result.
    """
    actor = RecorderActor()
    actor.start()
    
    try:
        session = actor.record(output_path, duration)
        return session
    finally:
        actor.stop()


class LoopRecorder:
    """Loop recording mode - manages multiple recording sessions.
    
    Uses Actor pattern internally for each segment.
    """
    
    def __init__(
        self,
        output_dir: Path,
        transcribe_callback: Optional[Callable[[Path], str]] = None
    ):
        self.output_dir = output_dir
        self.transcribe_callback = transcribe_callback
        self.sessions: list[RecordingSession] = []
    
    def run(self) -> list[RecordingSession]:
        """Run loop recording mode.
        
        Returns:
            List of all recording sessions
        """
        self.output_dir.mkdir(parents=True, exist_ok=True)
        segment = 1
        
        print(f"\n🎤 Loop Recording Mode")
        print(f"   Directory: {self.output_dir.absolute()}")
        print(f"   Controls: [Enter] = next segment | [q + Enter] = quit")
        print(f"   Press Enter to start first recording...")
        input()
        
        try:
            while True:
                output_path = self.output_dir / f"recording_{segment:03d}.wav"
                
                print(f"\n📼 Recording segment {segment}")
                
                # Record using actor
                actor = RecorderActor()
                actor.start()
                try:
                    session = actor.record(output_path)
                    self.sessions.append(session)
                    print(f"   ✓ Saved: {output_path.name} ({session.duration:.1f}s)")
                finally:
                    actor.stop()
                
                # Optional transcription
                if self.transcribe_callback:
                    try:
                        print("   📝 Transcribing...", end=" ")
                        text = self.transcribe_callback(output_path)
                        print(f"✓ ({len(text)} chars)")
                        print(f"   💬 {text[:100]}{'...' if len(text) > 100 else ''}")
                    except Exception as e:
                        print(f"✗ Failed: {e}")
                
                # Prompt for next action
                print(f"\n[Enter] = record segment {segment + 1} | [q + Enter] = quit")
                response = input().strip().lower()
                
                if response == "q":
                    print(f"\n✓ Loop mode complete. {len(self.sessions)} segments recorded.")
                    break
                
                segment += 1
                
        except KeyboardInterrupt:
            print(f"\n\n⚠️  Loop interrupted. {len(self.sessions)} segments saved.")
        
        return self.sessions
