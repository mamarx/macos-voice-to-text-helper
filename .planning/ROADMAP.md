# Roadmap: aihelper

## Overview

Three phases deliver the core voice-to-text loop on macOS. Phase 1 builds a menu bar app that captures audio via global hotkey. Phase 2 wires in whisper.cpp transcription and text insertion — completing the core value proposition. Phase 3 adds live codeword detection, the recording overlay, and the settings panel.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: App Shell & Audio Capture** - Menu bar app with global hotkey recording
- [x] **Phase 2: Transcription & Text Insertion** - Whisper transcription with cursor-position output
- [x] **Phase 3: Codeword, Overlay & Settings** - Live stop-word detection, recording UI, and configuration

## Phase Details

### Phase 1: App Shell & Audio Capture
**Goal**: User has a menu bar app that captures microphone audio on demand via global hotkey
**Depends on**: Nothing (first phase)
**Requirements**: REC-01, REC-02, REC-05, UI-01, UI-02
**Success Criteria** (what must be TRUE):
  1. App runs in menu bar with no dock icon; menu bar icon is visible
  2. Menu bar icon changes appearance to reflect idle vs recording state
  3. User can press a global hotkey from any application to start recording
  4. User can press the same hotkey again to stop recording
  5. Audio is captured from the microphone and saved to a usable format during recording
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Swift project setup and menu bar app shell with dynamic status icon
- [x] 01-02-PLAN.md — Global hotkey registration and microphone audio capture to WAV

### Phase 2: Transcription & Text Insertion
**Goal**: Recorded speech is transcribed locally and the text appears at the user's cursor
**Depends on**: Phase 1
**Requirements**: TRX-01, TRX-02, TRX-03, INS-01, INS-02
**Success Criteria** (what must be TRUE):
  1. After recording stops, audio is transcribed by a locally embedded whisper.cpp model with no network calls
  2. Transcription completes within 3 seconds for utterances under 30 seconds
  3. Transcribed text is inserted at the current cursor position in the active application
  4. If typing simulation fails, text is pasted via Cmd+V as fallback
  5. German and English speech are both transcribed correctly without manual language selection
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — whisper.cpp SPM integration, TranscriptionManager, and model download
- [x] 02-02-PLAN.md — Text insertion at cursor and end-to-end pipeline wiring

### Phase 3: Codeword, Overlay & Settings
**Goal**: User can stop recording by voice, see recording status visually, and configure all preferences
**Depends on**: Phase 2
**Requirements**: REC-03, REC-04, INS-03, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. User can say "over" (or configured codeword) during recording to stop it without touching the keyboard
  2. A floating overlay appears during recording showing a visual indicator (waveform or status) without stealing focus
  3. Settings panel is accessible from the menu bar with options for hotkey, codeword, insertion method, and auto-Enter toggle
  4. User can toggle auto-send Enter after text insertion and see it take effect immediately
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — Settings infrastructure, settings panel UI, and auto-Enter wiring
- [x] 03-02-PLAN.md — Live codeword detection via rolling buffer whisper transcription
- [x] 03-03-PLAN.md — Floating recording overlay with pulsing indicator

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. App Shell & Audio Capture | 2/2 | Complete | 2026-02-24 |
| 2. Transcription & Text Insertion | 2/2 | Complete | 2026-02-24 |
| 3. Codeword, Overlay & Settings | 3/3 | Complete   | 2026-02-24 |
