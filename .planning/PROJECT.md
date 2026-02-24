# aihelper

## What This Is

A native macOS menu bar app that converts speech to text using a locally embedded Whisper model. The user triggers recording with a global hotkey, speaks, and stops via the hotkey again or a configurable codeword (e.g. "over") that is detected live during recording. The transcribed text is automatically inserted at the current cursor position in whatever app is active.

## Core Value

Press a hotkey, speak, and the text appears where your cursor is — reliably, locally, without any cloud dependency.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Global hotkey to start/stop voice recording from any app
- [ ] Local Whisper model (whisper.cpp) for speech-to-text transcription
- [ ] Automatic language detection (primarily German and English)
- [ ] Live codeword detection ("over" by default) to stop recording without hotkey
- [ ] Configurable codeword in settings
- [ ] Text insertion at current cursor position (simulated typing)
- [ ] Clipboard-based paste (Cmd+V) as fallback insertion method
- [ ] Mini floating overlay showing recording status (waveform/indicator)
- [ ] Menu bar icon with status indication
- [ ] Settings: toggle auto-send Enter after text insertion
- [ ] Settings: choose insertion method (cursor position vs clipboard)
- [ ] macOS menu bar app (runs in background, no dock icon)

### Out of Scope

- Cloud-based speech recognition — core promise is local/private
- Cross-platform support — macOS only for v1
- AI post-processing or text correction — raw transcription only
- Multiple Whisper model sizes in UI — pick a good default
- Onboarding wizard — settings are minimal enough without one

## Context

- Target platform: macOS (Apple Silicon primary, Intel secondary)
- Tech stack: Native Swift/SwiftUI for the app, whisper.cpp for the speech model
- The app needs Accessibility permissions (for simulated typing) and Microphone permissions
- Global hotkey registration requires using macOS APIs (e.g. Carbon hotkeys or newer alternatives)
- Live codeword detection requires streaming audio analysis during recording — either a lightweight VAD + small model, or periodic Whisper passes on a rolling buffer
- whisper.cpp has Swift bindings and runs efficiently on Apple Silicon with CoreML/Metal support
- The mini overlay should be a floating panel (NSPanel) that stays on top but doesn't steal focus

## Constraints

- **Platform**: macOS 14+ (Sonoma) — leverages latest Swift/SwiftUI APIs
- **Privacy**: All processing must be local — no network calls for transcription
- **Performance**: Transcription should complete within 2-3 seconds of stopping recording for typical utterances (< 30 seconds of speech)
- **Size**: App bundle will be larger due to embedded Whisper model (~40-80MB for base/small model)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native Swift/SwiftUI over Tauri/Electron | Best macOS integration, smallest footprint, native menu bar support | — Pending |
| whisper.cpp over Apple Speech framework | Better accuracy for German, open source, no cloud, configurable | — Pending |
| Live codeword detection over post-processing | More natural UX — user doesn't have to remember to press hotkey | — Pending |
| Cursor-position insertion as default | Most natural — text appears where you're typing | — Pending |

---
*Last updated: 2026-02-24 after initialization*
