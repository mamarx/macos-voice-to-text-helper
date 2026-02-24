import SwiftUI

/// Manages the menu bar icon state, reflecting idle vs recording status.
///
/// Uses SwiftUI's ObservableObject so the MenuBarExtra icon updates reactively.
/// The actual audio recording logic will be added in Plan 02 -- for now,
/// `toggleRecording()` is a test mechanism that flips the visual state.
final class MenuBarManager: ObservableObject {
    /// Whether the app is currently recording audio.
    @Published var isRecording: Bool = false

    /// SF Symbol name for the current state.
    /// - Idle: `mic` (outline microphone)
    /// - Recording: `mic.fill` (filled microphone for clear visual distinction)
    var statusIconName: String {
        isRecording ? "mic.fill" : "mic"
    }

    /// Toggle recording state. Placeholder until real audio capture in Plan 02.
    func toggleRecording() {
        isRecording.toggle()
    }
}
