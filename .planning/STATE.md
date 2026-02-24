# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Press a hotkey, speak, and the text appears where your cursor is -- reliably, locally, without any cloud dependency.
**Current focus:** Phase 2: Transcription & Text Insertion

## Current Position

Phase: 2 of 3 (Transcription & Text Insertion)
Plan: 1 of 2 in current phase
Status: Phase 2 In Progress (02-01 complete)
Last activity: 2026-02-24 -- Completed 02-01-PLAN.md (whisper.cpp integration)

Progress: [█████░░░░░] 50%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: 3min
- Total execution time: 0.15 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 01 P01 | 2min | 2 tasks | 5 files |
| Phase 01 P02 | 5min | 3 tasks | 4 files |
| Phase 02 P01 | 2min | 2 tasks | 4 files |

**Recent Trend:**
- Last 5 plans: 2min, 5min, 2min
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

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 02-01-PLAN.md (whisper.cpp integration + model manager)
Resume file: None
