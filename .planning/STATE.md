# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Press a hotkey, speak, and the text appears where your cursor is -- reliably, locally, without any cloud dependency.
**Current focus:** Phase 3: Codeword, Overlay & Settings

## Current Position

Phase: 3 of 3 (Codeword, Overlay & Settings)
Plan: 2 of 3 in current phase
Status: Executing Phase 3
Last activity: 2026-02-24 -- Completed 03-02-PLAN.md (live codeword detection with rolling buffer whisper transcription)

Progress: [█████████░] 93%

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 3min
- Total execution time: 0.25 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 01 P01 | 2min | 2 tasks | 5 files |
| Phase 01 P02 | 5min | 3 tasks | 4 files |
| Phase 02 P01 | 2min | 2 tasks | 4 files |
| Phase 02 P02 | 2min | 2 tasks | 3 files |
| Phase 03 P01 | 2min | 2 tasks | 5 files |
| Phase 03 P02 | 2min | 2 tasks | 3 files |

**Recent Trend:**
- Last 5 plans: 2min, 2min, 2min, 2min, 2min
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Phase 01]: Used pure SwiftUI MenuBarExtra over AppKit NSStatusItem -- reactive icon updates work on macOS 14+
- [Phase 01]: Used SPM (Package.swift) over Xcode project for build -- lighter, CLI-friendly
- [Phase 01]: Used CGEvent tap over NSEvent.addGlobalMonitorForEvents -- can intercept and consume events, more reliable for system-wide hotkeys
- [Phase 01]: Used AVAudioEngine with AVAudioConverter for real-time format conversion to 16kHz/mono/16-bit target format expected by whisper.cpp
- [Phase 02]: Used whisper.spm branch master (not version tag) per whisper.spm README to avoid unsafe build flag errors
- [Phase 02]: Used ggml-base.bin model (not tiny) for better German+English accuracy while still under 3s transcription on Apple Silicon
- [Phase 02]: Actor pattern for TranscriptionManager to prevent concurrent access to whisper context pointer
- [Phase 02]: CGEvent typing simulation as primary text insertion with clipboard paste fallback for robustness
- [Phase 02]: Model initialization dispatched from MenuBarManager.init() via Task for cleanest @StateObject timing
- [Phase 03]: Used @AppStorage on SettingsManager singleton for automatic UserDefaults persistence with SwiftUI reactivity
- [Phase 03]: Used Window scene with openWindow(id:) instead of Settings scene -- Settings scene conflicts with menu-bar-only apps
- [Phase 03]: Extracted MenuBarContentView from App body to enable @Environment(\.openWindow) in menu bar dropdown
- [Phase 03]: InsertionMethod as String-backed enum for direct @AppStorage compatibility
- [Phase 03]: Used class (not actor) for CodewordDetector with serial DispatchQueue -- audio tap requires synchronous appendAudio
- [Phase 03]: Separate whisper context per detection session -- lightweight, OS memory-maps model weights
- [Phase 03]: 2-second detection interval with 4-second rolling buffer for codeword latency/CPU balance

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 03-02-PLAN.md (live codeword detection with rolling buffer whisper transcription)
Resume file: None
