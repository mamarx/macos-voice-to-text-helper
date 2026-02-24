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
            MenuBarContentView(menuBarManager: menuBarManager)
        }

        // Settings window — opened on demand from the menu bar.
        // Uses a Window scene with a stable id so the same window is reused.
        Window("aihelper Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 450, height: 400)
    }

    init() {
        // Check and prompt for Accessibility permissions on launch.
        // CGEvent taps require this to intercept global key events.
        HotkeyManager.ensureAccessibilityPermission()
    }
}

/// Menu bar dropdown content extracted into a View so we can use @Environment(\.openWindow).
///
/// @Environment only works inside View conformers, not directly in the App struct.
/// This view provides the recording toggle, settings button, and quit button.
private struct MenuBarContentView: View {
    @ObservedObject var menuBarManager: MenuBarManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(menuBarManager.isTranscribing ? "Transcribing..." :
               menuBarManager.isRecording ? "Stop Recording" : "Toggle Recording") {
            if !menuBarManager.isTranscribing {
                menuBarManager.toggleRecording()
            }
        }
        .keyboardShortcut("r")
        .disabled(menuBarManager.isTranscribing)

        Divider()

        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
