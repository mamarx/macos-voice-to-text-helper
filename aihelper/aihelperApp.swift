import SwiftUI

@main
struct aihelperApp: App {
    @StateObject private var menuBarManager = MenuBarManager()

    var body: some Scene {
        // Menu bar only app — no WindowGroup, no dock icon (LSUIElement=true in Info.plist).
        // The systemImage parameter re-evaluates when menuBarManager.statusIconName changes,
        // providing dynamic icon updates across three states:
        // idle (mic), recording (mic.fill), transcribing (text.bubble).
        MenuBarExtra("aihelper", systemImage: menuBarManager.statusIconName) {
            Button(menuBarManager.isTranscribing ? "Transcribing..." :
                   menuBarManager.isRecording ? "Stop Recording" : "Toggle Recording") {
                if !menuBarManager.isTranscribing {
                    menuBarManager.toggleRecording()
                }
            }
            .keyboardShortcut("r")
            .disabled(menuBarManager.isTranscribing)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    init() {
        // Check and prompt for Accessibility permissions on launch.
        // CGEvent taps require this to intercept global key events.
        HotkeyManager.ensureAccessibilityPermission()
    }
}
