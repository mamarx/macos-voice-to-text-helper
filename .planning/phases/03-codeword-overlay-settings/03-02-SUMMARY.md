---
phase: 03-codeword-overlay-settings
plan: 02
subsystem: audio
tags: [whisper, codeword, speech-detection, rolling-buffer, dispatch-timer]

# Dependency graph
requires:
  - phase: 03-codeword-overlay-settings
    provides: SettingsManager.shared.codeword for configurable stop word
  - phase: 02-transcription-text-insertion
    provides: AudioCaptureManager audio tap, TranscriptionManager whisper API patterns, MenuBarManager pipeline
provides:
  - CodewordDetector with rolling buffer periodic whisper transcription for live codeword detection
  - Audio buffer forwarding from AudioCaptureManager to CodewordDetector during recording
  - Automatic recording stop when codeword is spoken
  - Codeword stripping from final transcription output
affects: [03-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [rolling buffer with periodic whisper passes, DispatchSourceTimer for timed detection, separate lightweight whisper context]

key-files:
  created:
    - aihelper/CodewordDetector.swift
  modified:
    - aihelper/AudioCaptureManager.swift
    - aihelper/MenuBarManager.swift

key-decisions:
  - "Used class (not actor) for CodewordDetector with serial DispatchQueue -- audio tap callback requires synchronous appendAudio"
  - "Separate whisper context per detection session -- lightweight (~20MB), OS memory-maps model weights"
  - "2-second detection interval with 4-second rolling buffer -- balances latency vs CPU overhead"
  - "Codeword stripping handles both bare word and word+punctuation suffixes"

patterns-established:
  - "CodewordDetector lifecycle: start() on recording begin, stop() on recording end, nil out reference"
  - "Audio forwarding: Int16 tap buffer converted to Float and forwarded to detector via appendAudio"

requirements-completed: [REC-03, REC-04]

# Metrics
duration: 2min
completed: 2026-02-24
---

# Phase 3 Plan 02: Codeword Detection Summary

**Live codeword detection via rolling buffer whisper transcription -- say "over" during recording and it stops automatically, stripping the codeword from output**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-24T09:55:42Z
- **Completed:** 2026-02-24T09:57:36Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- CodewordDetector with rolling 4-second audio buffer and periodic 2-second whisper transcription passes
- Real-time audio buffer forwarding from AudioCaptureManager tap to CodewordDetector
- Automatic recording stop triggered by codeword detection via callback to MenuBarManager
- Codeword stripped from end of final transcription (handles "over", "over.", " Over" etc.)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CodewordDetector with rolling buffer whisper transcription** - `dd2e1e6` (feat)
2. **Task 2: Wire codeword detection into audio capture and recording pipeline** - `543c99f` (feat)

## Files Created/Modified
- `aihelper/CodewordDetector.swift` - Rolling buffer periodic whisper transcription for live codeword detection with configurable stop word
- `aihelper/AudioCaptureManager.swift` - Added codewordDetector property and Int16-to-Float audio forwarding in tap closure
- `aihelper/MenuBarManager.swift` - Added codewordDetector lifecycle wiring (start/stop with recording) and codeword stripping from transcription output

## Decisions Made
- Used class (not actor) for CodewordDetector with serial DispatchQueue -- the audio tap callback calls appendAudio synchronously and cannot await an actor method
- Created a separate whisper context per detection session rather than sharing with TranscriptionManager -- avoids concurrent access issues and the OS memory-maps model weights so overhead is minimal (~20MB)
- Detection interval of 2 seconds with 4-second buffer provides good latency/CPU balance -- codeword detected within 2-3 seconds of speaking
- Codeword stripping checks both bare word suffix and word+punctuation suffix to handle whisper outputting "over." or "Over"

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Codeword detection fully integrated into recording pipeline
- Ready for Plan 03 (floating overlay) -- overlay can show recording state while codeword detection runs in background
- SettingsManager.shared.codeword changes are picked up immediately (read on each detection check)

## Self-Check: PASSED

All 3 files verified present. Both task commits (dd2e1e6, 543c99f) verified in git log.

---
*Phase: 03-codeword-overlay-settings*
*Completed: 2026-02-24*
