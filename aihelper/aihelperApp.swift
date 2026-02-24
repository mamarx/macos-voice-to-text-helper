import SwiftUI

@main
struct aihelperApp: App {
    @StateObject private var menuBarManager = MenuBarManager()

    var body: some Scene {
        // Menu bar only app — no WindowGroup, no dock icon (LSUIElement=true in Info.plist).
        // The systemImage parameter re-evaluates when menuBarManager.statusIconName changes,
        // providing dynamic icon updates between idle (mic) and recording (mic.fill) states.
        MenuBarExtra("aihelper", systemImage: menuBarManager.statusIconName) {
            Button(menuBarManager.isRecording ? "Stop Recording" : "Toggle Recording") {
                menuBarManager.toggleRecording()
            }
            .keyboardShortcut("r")

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
