import Cocoa
import SwiftUI

/// A floating overlay window that displays a recording indicator without stealing focus.
///
/// Uses NSPanel with `.nonActivatingPanel` style mask so it floats on top of all windows
/// but never takes keyboard focus away from the app where the user is typing.
/// Visible on all Spaces/desktops and even over fullscreen apps.
final class RecordingOverlayWindow {
    private var panel: NSPanel?

    func show() {
        if panel != nil { return }  // Already showing

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating          // Always on top
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false   // Stay visible even when app is not frontmost

        // Host the SwiftUI view
        let hostingView = NSHostingView(rootView: RecordingOverlayView())
        panel.contentView = hostingView

        // Position: bottom-center of screen, ~80px from bottom
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 60  // center horizontally (120/2 = 60)
            let y = screenFrame.minY + 80   // 80px from bottom
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}
