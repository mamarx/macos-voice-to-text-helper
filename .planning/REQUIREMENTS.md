# Requirements: aihelper

**Defined:** 2026-02-24
**Core Value:** Press a hotkey, speak, and the text appears where your cursor is — reliably, locally, without any cloud dependency.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Recording & Control

- [x] **REC-01**: User can start voice recording with a global hotkey from any app
- [x] **REC-02**: User can stop voice recording by pressing the global hotkey again
- [x] **REC-03**: User can stop voice recording by saying a codeword (default: "over") detected live during recording
- [x] **REC-04**: User can configure the stop codeword in settings
- [x] **REC-05**: App captures microphone audio during recording

### Transcription

- [x] **TRX-01**: App transcribes recorded audio using locally embedded whisper.cpp model
- [x] **TRX-02**: Transcription completes within 3 seconds for utterances under 30 seconds
- [x] **TRX-03**: App automatically detects spoken language (German and English primarily)

### Text Insertion

- [x] **INS-01**: Transcribed text is inserted at the current cursor position in the active app (simulated typing)
- [x] **INS-02**: App falls back to clipboard paste (Cmd+V) when typing simulation fails
- [x] **INS-03**: User can toggle auto-send Enter after text insertion in settings

### UI & Feedback

- [x] **UI-01**: App runs as a macOS menu bar app (no dock icon)
- [x] **UI-02**: Menu bar icon indicates current state (idle, recording, transcribing)
- [ ] **UI-03**: Mini floating overlay appears during recording showing status/waveform
- [x] **UI-04**: Settings panel accessible from menu bar for configuring hotkey, codeword, Enter toggle, insertion method

## v2 Requirements

### Enhanced Transcription

- **TRX-04**: User can select Whisper model size (tiny/base/small/medium) in settings
- **TRX-05**: App supports custom vocabulary / proper noun hints

### Quality of Life

- **QOL-01**: App auto-starts on login
- **QOL-02**: Onboarding flow for first launch (permissions, hotkey setup)
- **QOL-03**: History of recent transcriptions accessible from menu bar

### Advanced Features

- **ADV-01**: AI post-processing for punctuation/formatting improvement
- **ADV-02**: Text correction/rephrasing via LLM before insertion

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud-based speech recognition | Core promise is local/private processing |
| Cross-platform (Windows/Linux) | macOS native first, other platforms later |
| Real-time streaming transcription display | Adds complexity, batch transcription sufficient for v1 |
| Multiple simultaneous audio sources | Single microphone input sufficient |
| Voice commands beyond stop-word | Not a voice assistant, just voice-to-text |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REC-01 | Phase 1 | Complete |
| REC-02 | Phase 1 | Complete |
| REC-03 | Phase 3 | Complete |
| REC-04 | Phase 3 | Complete |
| REC-05 | Phase 1 | Complete |
| TRX-01 | Phase 2 | Complete |
| TRX-02 | Phase 2 | Complete |
| TRX-03 | Phase 2 | Complete |
| INS-01 | Phase 2 | Complete |
| INS-02 | Phase 2 | Complete |
| INS-03 | Phase 3 | Complete |
| UI-01 | Phase 1 | Complete |
| UI-02 | Phase 1 | Complete |
| UI-03 | Phase 3 | Pending |
| UI-04 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-24 after 02-01-PLAN completion*
