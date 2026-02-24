import SwiftUI

/// Manages the menu bar icon state, reflecting idle vs recording status.
///
/// Uses SwiftUI's ObservableObject so the MenuBarExtra icon updates reactively.
/// Owns the HotkeyManager and wires the global hotkey to toggle recording.
final class MenuBarManager: ObservableObject {
    /// Whether the app is currently recording audio.
    @Published var isRecording: Bool = false

    /// Global hotkey manager — listens for Ctrl+Shift+Space system-wide.
    private let hotkeyManager = HotkeyManager()

    /// SF Symbol name for the current state.
    /// - Idle: `mic` (outline microphone)
    /// - Recording: `mic.fill` (filled microphone for clear visual distinction)
    var statusIconName: String {
        isRecording ? "mic.fill" : "mic"
    }

    init() {
        // Wire global hotkey to toggle recording
        hotkeyManager.onToggle = { [weak self] in
            self?.toggleRecording()
        }
        hotkeyManager.start()
    }

    /// Toggle recording state.
    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            print("[MenuBarManager] Recording started")
        } else {
            print("[MenuBarManager] Recording stopped")
        }
    }

    deinit {
        hotkeyManager.stop()
    }
}
