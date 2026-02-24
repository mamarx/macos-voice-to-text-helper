---
phase: 01-app-shell-audio-capture
plan: 02
subsystem: audio
tags: [swift, cgevent, avaudioengine, hotkey, microphone, wav, macos]

# Dependency graph
requires:
  - phase: 01-app-shell-audio-capture plan 01
    provides: SwiftUI menu bar app shell with MenuBarManager ObservableObject
provides:
  - Global hotkey registration (Ctrl+Shift+Space) via CGEvent tap
  - Microphone audio capture to 16kHz mono 16-bit WAV files
  - End-to-end recording flow: hotkey -> capture -> WAV file
  - Accessibility and microphone permission handling
affects: [02-transcription]

# Tech tracking
tech-stack:
  added: [CGEvent tap, AVAudioEngine, AVAudioConverter, Carbon (key codes)]
  patterns: [CGEvent tap for global hotkey interception, AVAudioEngine with format conversion for audio capture, Unmanaged bridge for C callback context]

key-files:
  created:
    - aihelper/HotkeyManager.swift
    - aihelper/AudioCaptureManager.swift
  modified:
    - aihelper/MenuBarManager.swift
    - aihelper/aihelperApp.swift

key-decisions:
  - "Used CGEvent tap over NSEvent.addGlobalMonitorForEvents -- can intercept and consume events, more reliable for system-wide hotkeys"
  - "Used AVAudioEngine with AVAudioConverter for real-time format conversion to 16kHz/mono/16-bit target format expected by whisper.cpp"

patterns-established:
  - "Global hotkey: CGEvent tap with Unmanaged bridge to pass instance context into C callback"
  - "Audio capture: AVAudioEngine tap on input node bus 0 with AVAudioConverter to target format"
  - "Permission flow: AXIsProcessTrustedWithOptions for Accessibility, AVCaptureDevice.requestAccess for Microphone"

requirements-completed: [REC-01, REC-02, REC-05]

# Metrics
duration: 5min
completed: 2026-02-24
---

# Phase 1 Plan 02: Global Hotkey & Audio Capture Summary

**Global hotkey (Ctrl+Shift+Space) via CGEvent tap toggles microphone recording to 16kHz mono WAV files using AVAudioEngine with real-time format conversion**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-24T09:15:58Z
- **Completed:** 2026-02-24T09:21:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Files modified:** 4

## Accomplishments
- Global hotkey (Ctrl+Shift+Space) works from any application via CGEvent tap with Accessibility permission handling
- Microphone audio captured to 16kHz/mono/16-bit PCM WAV files via AVAudioEngine with real-time format conversion
- End-to-end recording flow verified: hotkey toggles recording, WAV file saved to temp directory
- Permission dialogs (Accessibility + Microphone) presented gracefully on first use

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement global hotkey registration** - `45a714c` (feat)
2. **Task 2: Implement microphone audio capture to WAV** - `bf8936a` (feat)
3. **Task 3: Verify end-to-end recording flow** - checkpoint approved (no code commit)

## Files Created/Modified
- `aihelper/HotkeyManager.swift` - CGEvent tap for global Ctrl+Shift+Space hotkey with onToggle callback, Accessibility permission check
- `aihelper/AudioCaptureManager.swift` - AVAudioEngine microphone capture with AVAudioConverter to 16kHz/mono/16-bit WAV, start/stop lifecycle
- `aihelper/MenuBarManager.swift` - Orchestration: AudioCaptureManager integration, toggleRecording() wires hotkey to audio capture, microphone permission request
- `aihelper/aihelperApp.swift` - HotkeyManager creation and wiring to MenuBarManager.toggleRecording()

## Decisions Made
- **CGEvent tap over NSEvent global monitor**: CGEvent tap was chosen because it can intercept events at the session level, is more reliable for system-wide hotkeys, and can optionally consume the event. NSEvent.addGlobalMonitorForEvents is simpler but cannot consume events.
- **AVAudioEngine with AVAudioConverter**: Hardware microphone format varies by device (often 48kHz stereo float). AVAudioConverter handles real-time conversion to the 16kHz/mono/16-bit integer format that whisper.cpp expects in Phase 2.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None - both implementation tasks executed smoothly and built successfully.

## User Setup Required
None - no external service configuration required. Permissions (Accessibility, Microphone) are requested via system dialogs at runtime.

## Next Phase Readiness
- Complete Phase 1 end-to-end flow working: menu bar app -> hotkey -> audio capture -> WAV file
- WAV files are in 16kHz/mono/16-bit format, ready for whisper.cpp transcription in Phase 2
- AudioCaptureManager.lastRecordingURL provides the file path for the transcription pipeline
- All Phase 1 success criteria met: menu bar only, icon toggles, hotkey works, audio captured

## Self-Check: PASSED

All files exist, all commits verified.

---
*Phase: 01-app-shell-audio-capture*
*Completed: 2026-02-24*
