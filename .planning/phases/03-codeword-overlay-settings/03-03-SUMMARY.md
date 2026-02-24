---
phase: 03-codeword-overlay-settings
plan: 03
subsystem: ui
tags: [nsPanel, swiftui, overlay, recording-indicator, settings-window]

# Dependency graph
requires:
  - phase: 03-codeword-overlay-settings/03-01
    provides: SettingsManager with showOverlay preference, SettingsView UI
provides:
  - NSPanel-based floating recording overlay that appears during recording
  - SettingsWindowController for reliable settings panel in LSUIElement apps
  - Visual recording feedback without focus stealing
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NSPanel with .nonActivatingPanel for focus-safe floating windows"
    - "NSWindow direct instantiation over SwiftUI Window scene for LSUIElement apps"
    - "SettingsWindowController singleton for settings panel lifecycle"

key-files:
  created:
    - aihelper/RecordingOverlayWindow.swift
    - aihelper/RecordingOverlayView.swift
  modified:
    - aihelper/MenuBarManager.swift
    - aihelper/aihelperApp.swift

key-decisions:
  - "NSPanel with .nonActivatingPanel + .borderless for overlay that never steals focus"
  - "Replaced SwiftUI Window scene + openWindow with direct NSWindow -- openWindow unreliable in LSUIElement apps"
  - "SettingsWindowController singleton manages NSWindow lifecycle for settings panel"

patterns-established:
  - "NSPanel floating overlay: .nonActivatingPanel, .floating level, canJoinAllSpaces, hidesOnDeactivate=false"
  - "Direct NSWindow for UI panels in menu-bar-only (LSUIElement) apps instead of SwiftUI Window scene"

requirements-completed: [UI-03]

# Metrics
duration: 2min
completed: 2026-02-24
---

# Phase 3 Plan 3: Recording Overlay Summary

**NSPanel floating recording overlay with pulsing indicator, wired to recording state and user preference, plus NSWindow-based settings panel fix**

## Performance

- **Duration:** 2 min (continuation after checkpoint approval)
- **Started:** 2026-02-24T10:10:58Z
- **Completed:** 2026-02-24T10:11:23Z
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Files modified:** 4

## Accomplishments
- Created NSPanel-based floating overlay that shows during recording without stealing focus
- Pulsing red recording indicator in a pill-shaped SwiftUI view
- Overlay wired to MenuBarManager recording lifecycle, respects showOverlay preference
- Fixed settings panel -- replaced unreliable SwiftUI Window scene with direct NSWindow via SettingsWindowController

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RecordingOverlayWindow and RecordingOverlayView** - `ff97b89` (feat)
2. **Task 2: Wire overlay show/hide to recording state in MenuBarManager** - `d20b7e8` (feat)
3. **Task 3: Verify recording overlay and settings panel** - checkpoint approved by user
4. **Fix: Replace SwiftUI Window scene with NSWindow for settings** - `9c874a5` (fix)

## Files Created/Modified
- `aihelper/RecordingOverlayWindow.swift` - NSPanel wrapper that floats on top without stealing focus, positioned bottom-center
- `aihelper/RecordingOverlayView.swift` - SwiftUI view with pulsing red circle and "Recording" label in a pill-shaped capsule
- `aihelper/MenuBarManager.swift` - Added overlayWindow show/hide on recording start/stop, respects showOverlay setting
- `aihelper/aihelperApp.swift` - Replaced Window scene + openWindow with SettingsWindowController using direct NSWindow

## Decisions Made
- NSPanel with `.nonActivatingPanel` + `.borderless` style mask ensures the overlay never steals focus from the user's active application
- `canJoinAllSpaces` + `fullScreenAuxiliary` makes overlay visible across all Spaces and even over fullscreen apps
- `isMovableByWindowBackground = true` lets users drag the overlay to reposition it
- Replaced SwiftUI `Window` scene + `@Environment(\.openWindow)` with direct `NSWindow` in `SettingsWindowController` because openWindow is unreliable in LSUIElement (menu-bar-only) apps

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Settings window not opening via SwiftUI Window scene**
- **Found during:** Task 3 (checkpoint verification)
- **Issue:** `@Environment(\.openWindow)` does not reliably open windows in LSUIElement menu-bar-only apps -- the settings panel failed to appear
- **Fix:** Created SettingsWindowController singleton that directly instantiates NSWindow with NSHostingView(rootView: SettingsView()), inlined menu content back into App body
- **Files modified:** aihelper/aihelperApp.swift
- **Verification:** Build succeeds, settings panel opens on click
- **Committed in:** `9c874a5`

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Essential fix for settings panel to work in LSUIElement context. No scope creep.

## Issues Encountered
None beyond the settings window fix documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 3 is now complete: all three plans (settings infrastructure, codeword detection, recording overlay) delivered
- The application has full functionality: hotkey recording, whisper transcription, text insertion, codeword detection, floating overlay, and settings panel
- Ready for production use or further refinement

## Self-Check: PASSED

All files exist, all commits verified, SUMMARY.md created.

---
*Phase: 03-codeword-overlay-settings*
*Completed: 2026-02-24*
