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
        guard panel == nil else { return }  // Already showing

        let size = NSSize(width: 150, height: 44)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        // Use a fixed-size hosting view to avoid constraint-based resizing crashes
        // in borderless NSPanels.
        let hostingView = NSHostingView(rootView: RecordingOverlayView())
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = []
        panel.contentView = hostingView

        // Position: bottom-center of screen, ~80px from bottom
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.minY + 80
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
