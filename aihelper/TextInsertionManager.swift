import Cocoa

/// Inserts transcribed text at the current cursor position in the active application.
///
/// Respects `SettingsManager.shared.insertionMethod` to choose between CGEvent typing
/// simulation and clipboard paste. When typing is selected, falls back to clipboard
/// paste if CGEvent creation fails. After successful insertion, optionally simulates
/// a Return key press when `SettingsManager.shared.autoEnterEnabled` is true.
///
/// Both methods require Accessibility permission, which is already requested
/// by HotkeyManager on app launch for CGEvent tap.
final class TextInsertionManager {

    /// Inserts the given text at the current cursor position.
    ///
    /// Respects the user's insertion method preference from settings:
    /// - `.typing`: tries CGEvent keystroke simulation first, falls back to clipboard paste.
    /// - `.clipboard`: goes directly to clipboard paste.
    ///
    /// After successful insertion, simulates Return key if auto-Enter is enabled.
    ///
    /// - Parameter text: The text string to insert.
    func insertText(_ text: String) {
        guard !text.isEmpty else { return }

        let settings = SettingsManager.shared

        switch settings.insertionMethod {
        case .typing:
            // Try typing simulation first, fall back to clipboard paste
            if !insertViaTypingSimulation(text) {
                print("[TextInsertionManager] Typing simulation failed, falling back to clipboard paste")
                insertViaClipboardPaste(text)
            }
        case .clipboard:
            insertViaClipboardPaste(text)
        }

        // Simulate Return key after insertion if auto-Enter is enabled
        if settings.autoEnterEnabled {
            simulateReturnKey()
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

    // MARK: - Auto-Enter: Return Key Simulation

    /// Simulates pressing the Return key via CGEvent keyDown + keyUp.
    ///
    /// Virtual key code 36 = Return key on macOS.
    /// Posted to `.cghidEventTap` so it reaches the active application.
    /// Small delay before pressing to let the preceding text insertion settle.
    private func simulateReturnKey() {
        // Brief pause so the text insertion completes before Enter
        usleep(50_000)  // 50ms

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 36, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 36, keyDown: false) else {
            print("[TextInsertionManager] Failed to create Return key CGEvent")
            return
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        print("[TextInsertionManager] Simulated Return key press (auto-Enter)")
    }
}
