import SwiftUI

@main
struct aihelperApp: App {
    var body: some Scene {
        // Menu bar presence with mic icon — no WindowGroup (menu bar only app)
        MenuBarExtra("aihelper", systemImage: "mic") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
