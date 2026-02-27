# macOS Voice-to-Text Helper

A native macOS menu bar app for local voice-to-text transcription. Press a hotkey, speak, and the transcribed text appears at your cursor — no cloud, no API keys, fully offline.

Built with Swift and [whisper.cpp](https://github.com/ggerganov/whisper.cpp) for fast, private speech recognition on Apple Silicon.

## Features

- **Global Hotkey** — `Ctrl+Shift+Space` starts/stops recording from any app, including fullscreen
- **Voice Stop Command** — Say "over" (configurable) to stop recording hands-free
- **Local Transcription** — Runs entirely on-device using whisper.cpp with Metal acceleration
- **Auto Language Detection** — Supports English and German without manual selection
- **Smart Text Insertion** — Types text character-by-character (preserves clipboard) or pastes via clipboard
- **Optional Auto-Enter** — Automatically sends Return after insertion
- **Menu Bar App** — Lives in your menu bar with status icons (idle / recording / transcribing)
- **Recording Overlay** — Floating indicator with pulsing red dot, visible on all Spaces

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended (Intel supported but slower)
- ~250 MB disk space for Whisper models (downloaded on first launch)

## Build & Run

```bash
git clone https://github.com/mamarx/macos-voice-to-text-helper.git
cd macos-voice-to-text-helper
swift build -c release
swift run aihelper
```

The app appears as a microphone icon in your menu bar.

## First Launch Setup

### 1. Grant Permissions

On first launch, macOS will prompt for two permissions:

- **Accessibility** — Required for the global hotkey and text insertion. Enable in **System Settings → Privacy & Security → Accessibility**.
- **Microphone** — Prompted on first recording. Enable in **System Settings → Privacy & Security → Microphone**.

### 2. Model Download

Whisper models are downloaded automatically on first use:

| Model | Size | Purpose |
|-------|------|---------|
| `ggml-base.bin` | ~148 MB | Main transcription (accuracy-optimized) |
| `ggml-tiny.bin` | ~75 MB | Codeword detection (speed-optimized) |

Models are stored in `~/Library/Application Support/aihelper/models/`. This is the only network activity — everything else runs offline.

## Usage

1. **Press `Ctrl+Shift+Space`** to start recording (microphone icon fills, overlay appears)
2. **Speak** — the app captures audio at 16kHz mono
3. **Stop** by either:
   - Pressing `Ctrl+Shift+Space` again
   - Saying the stop codeword ("over" by default)
4. **Text appears** at your cursor position in whatever app is active

Transcription typically completes in under 3 seconds for 30-second utterances on Apple Silicon.

## Settings

Open settings from the menu bar icon or with `Cmd+,`.

| Setting | Default | Description |
|---------|---------|-------------|
| Stop Codeword | `over` | Word to say to stop recording hands-free |
| Insertion Method | Typing | `Typing` simulates keystrokes (preserves clipboard), `Clipboard` uses paste |
| Auto-send Enter | Off | Automatically press Return after inserting text |
| Show Overlay | On | Display floating recording indicator |

## How It Works

```
Hotkey (Ctrl+Shift+Space)
  → Audio Capture (AVAudioEngine, 16kHz mono)
  → In-Memory Sample Buffer (no disk I/O)
  → Parallel:
      • Codeword Detection (tiny model, 1s rolling checks)
      • Final Transcription (base model, after recording stops)
  → Text Insertion (CGEvent typing or clipboard paste)
  → Optional: Auto-send Return key
```

Key architecture decisions:
- **In-memory pipeline** — Audio samples stay in RAM, skipping disk I/O for ~50–200ms faster processing
- **Pre-warmed contexts** — Whisper contexts are initialized at launch, not per-recording
- **Dual-model approach** — Tiny model for fast codeword detection, base model for accurate transcription
- **CGEvent tap** — System-level hotkey that works in any app, even fullscreen

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hotkey doesn't work | Grant Accessibility permission in System Settings |
| No audio captured | Grant Microphone permission in System Settings |
| Slow first transcription | Models are downloading (~250 MB total), wait for completion |
| Text not appearing | Try switching insertion method to Clipboard in Settings |
| Codeword not detected | Speak clearly, check codeword spelling in Settings |

## Tech Stack

- **Swift 5.9+** / SwiftUI + AppKit
- **whisper.cpp** via [whisper.spm](https://github.com/ggerganov/whisper.spm) (Metal/CoreML acceleration)
- **AVAudioEngine** for capture
- **CGEvent** for global hotkey and text insertion
- Swift Package Manager for builds

## License

MIT
