# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Press a hotkey, speak, and the text appears where your cursor is -- reliably, locally, without any cloud dependency.
**Current focus:** Phase 3: Codeword, Overlay & Settings

## Current Position

Phase: 3 of 3 (Codeword, Overlay & Settings)
Plan: 3 of 3 in current phase
Status: Phase 3 Complete -- All phases complete
Last activity: 2026-02-24 - Completed quick task 1: Speed optimization — faster codeword detection and speech processing

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 2min
- Total execution time: 0.28 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 01 P01 | 2min | 2 tasks | 5 files |
| Phase 01 P02 | 5min | 3 tasks | 4 files |
| Phase 02 P01 | 2min | 2 tasks | 4 files |
| Phase 02 P02 | 2min | 2 tasks | 3 files |
| Phase 03 P01 | 2min | 2 tasks | 5 files |
| Phase 03 P02 | 2min | 2 tasks | 3 files |
| Phase 03 P03 | 2min | 3 tasks | 4 files |

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
- [Phase 03]: Replaced Window scene + openWindow(id:) with direct NSWindow via SettingsWindowController -- openWindow unreliable in LSUIElement apps
- [Phase 03]: InsertionMethod as String-backed enum for direct @AppStorage compatibility
- [Phase 03]: Used class (not actor) for CodewordDetector with serial DispatchQueue -- audio tap requires synchronous appendAudio
- [Phase 03]: Separate whisper context per detection session -- lightweight, OS memory-maps model weights
- [Phase 03]: 2-second detection interval with 4-second rolling buffer for codeword latency/CPU balance
- [Phase 03]: NSPanel with .nonActivatingPanel + .borderless for floating overlay that never steals focus
- [Phase 03]: canJoinAllSpaces + fullScreenAuxiliary for overlay visible on all Spaces and over fullscreen apps
- [Phase quick-1]: Use ggml-tiny for codeword detection, keep ggml-base for main transcription -- 5x faster inference for periodic detection
- [Phase quick-1]: Pre-warm codeword context at app launch, reuse across sessions -- zero per-session overhead
- [Phase quick-1]: In-memory transcription pipeline: accumulate Float samples, skip disk I/O and format conversion

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Speed optimization — faster codeword detection and speech processing | 2026-02-24 | 4d6213d | [1-speed-optimization-faster-codeword-detec](./quick/1-speed-optimization-faster-codeword-detec/) |

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed quick-1 speed optimization plan (ggml-tiny codeword, pre-warmed context, in-memory transcription)
Resume file: None
