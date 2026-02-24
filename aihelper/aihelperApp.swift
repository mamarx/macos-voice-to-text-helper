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

            Button("Settings...") {
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(",")

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

/// Manages a single NSWindow hosting SettingsView.
///
/// Uses NSWindow directly instead of SwiftUI Window scene because
/// @Environment(\.openWindow) is unreliable from MenuBarExtra in LSUIElement apps.
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "aihelper Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        self.window = window

        // For LSUIElement apps the activation must happen after a brief delay
        // so the menu bar dropdown has time to dismiss first.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}
