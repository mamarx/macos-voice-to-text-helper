---
status: complete
phase: 03-codeword-overlay-settings
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md]
started: 2026-02-24T10:30:00Z
updated: 2026-02-24T11:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Settings panel opens from menu bar
expected: Click menu bar icon, click "Settings..." — window opens in foreground with four sections (Recording, Text Insertion, Overlay, Hotkey)
result: pass

### 2. Settings persist across app restart
expected: Change codeword to "stop" in Settings, quit app, relaunch — Settings still shows "stop" as codeword
result: pass

### 3. Recording overlay appears during recording
expected: Ensure "Show recording overlay" is ON in Settings. Press Ctrl+Shift+Space — a floating pill-shaped overlay appears at bottom-center of screen with a pulsing red dot and "Recording" text
result: pass

### 4. Overlay does not steal focus
expected: Have a text editor in the foreground. Start recording — the overlay appears but the text editor stays focused (you can still type in it)
result: pass

### 5. Overlay disappears when recording stops
expected: While recording with overlay visible, press Ctrl+Shift+Space to stop — overlay disappears immediately
result: pass

### 6. Overlay toggle controls visibility
expected: Turn OFF "Show recording overlay" in Settings. Start recording — no overlay appears. Turn it back ON, start recording — overlay appears again
result: pass

### 7. Codeword stops recording by voice
expected: Start recording, say a sentence ending with "over" (or whatever codeword is configured). Within 2-3 seconds of saying the codeword, recording stops automatically without pressing the hotkey
result: pass

### 8. Codeword stripped from transcription
expected: Start recording, say "hello world over". After recording stops (triggered by codeword), the inserted text should be "hello world" without the word "over"
result: pass

### 9. Auto-Enter sends Return after text insertion
expected: Enable "Auto-send Enter after insertion" in Settings. Record a phrase and let it transcribe — after the text is inserted, a Return/Enter keystroke is automatically sent
result: pass

### 10. Insertion method switching
expected: In Settings, switch from "Typing Simulation" to "Clipboard Paste". Record and transcribe — text still inserts correctly at cursor. Switch back to "Typing Simulation" — still works
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
