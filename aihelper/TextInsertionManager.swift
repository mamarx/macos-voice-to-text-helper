import Cocoa

/// Inserts transcribed text at the current cursor position in the active application.
///
/// Uses CGEvent-based typing simulation as the primary method. Falls back to
/// clipboard paste (Cmd+V) if typing simulation fails (e.g. when target app
/// rejects synthetic events or Accessibility permission is insufficient for
/// event posting).
///
/// Both methods require Accessibility permission, which is already requested
/// by HotkeyManager on app launch for CGEvent tap.
final class TextInsertionManager {

    /// Inserts the given text at the current cursor position.
    ///
    /// Tries CGEvent keystroke simulation first (preserves clipboard contents).
    /// Falls back to Cmd+V paste if any CGEvent creation returns nil.
    ///
    /// - Parameter text: The text string to insert.
    func insertText(_ text: String) {
        guard !text.isEmpty else { return }

        // Try typing simulation first
        if !insertViaTypingSimulation(text) {
            print("[TextInsertionManager] Typing simulation failed, falling back to clipboard paste")
            insertViaClipboardPaste(text)
        }
    }

    // MARK: - Primary: CGEvent Typing Simulation

    /// Simulates typing each character via CGEvent keyDown/keyUp pairs.
    ///
    /// Posts events to `.cghidEventTap` which works for simulating input to
    /// other applications. Returns false if any CGEvent creation fails.
    private func insertViaTypingSimulation(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            var utf16Unit = UInt16(scalar.value & 0xFFFF)

            // Create keyDown event
            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
                return false
            }
            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &utf16Unit)
            keyDown.post(tap: .cghidEventTap)

            // Create matching keyUp event
            guard let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
                return false
            }
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &utf16Unit)
            keyUp.post(tap: .cghidEventTap)

            // Small delay to avoid overwhelming the receiving application
            usleep(1000)  // 1ms between characters
        }

        return true
    }

    // MARK: - Fallback: Clipboard Paste (Cmd+V)

    /// Inserts text via clipboard paste with save/restore of existing clipboard content.
    ///
    /// Saves current clipboard, sets transcribed text, simulates Cmd+V,
    /// then restores original clipboard after a short delay.
    private func insertViaClipboardPaste(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard content
        let previousContent = pasteboard.string(forType: .string)

        // Set transcribed text on clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V keystroke
        // Virtual key code 9 = 'v' key
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            print("[TextInsertionManager] Failed to create Cmd+V CGEvent")
            // Restore clipboard even if paste fails
            if let previous = previousContent {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // Wait for paste to complete, then restore clipboard
        usleep(100_000)  // 100ms

        if let previous = previousContent {
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }
    }
}
