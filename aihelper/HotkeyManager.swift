import Cocoa
import Carbon

/// Manages global hotkey registration using CGEvent taps.
///
/// Registers a system-wide event tap to detect Ctrl+Shift+Space from any application.
/// Requires Accessibility permissions (prompted on first launch).
final class HotkeyManager {
    /// Callback invoked on the main thread when the hotkey is pressed.
    var onToggle: (() -> Void)?

    /// The key code for Space (Carbon virtual key code).
    private let keyCode: CGKeyCode = 49  // kVK_Space

    /// Required modifier flags: Control + Shift.
    private let requiredModifiers: CGEventFlags = [.maskControl, .maskShift]

    /// The event tap mach port, retained to keep the tap alive.
    private var eventTap: CFMachPort?

    /// Run loop source for the event tap.
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Accessibility Permission

    /// Checks if Accessibility permission is granted.
    /// If not, prompts the user with the system dialog.
    @discardableResult
    static func ensureAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            // Show system permission prompt
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
        return trusted
    }

    // MARK: - Start / Stop

    /// Creates and enables the global event tap.
    /// Must be called after Accessibility permission is granted.
    func start() {
        guard eventTap == nil else { return }

        // Use Unmanaged to pass self into the C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()

                // If the tap gets disabled by the system (e.g., after timeout), re-enable it
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                // Check key code
                let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                guard keyCode == manager.keyCode else {
                    return Unmanaged.passUnretained(event)
                }

                // Check modifier flags — must have both Control and Shift,
                // but ignore other flags (like caps lock, fn, etc.)
                let flags = event.flags
                let hasControl = flags.contains(.maskControl)
                let hasShift = flags.contains(.maskShift)
                // Exclude Command and Option to avoid conflicts
                let hasCommand = flags.contains(.maskCommand)
                let hasOption = flags.contains(.maskAlternate)

                if hasControl && hasShift && !hasCommand && !hasOption {
                    DispatchQueue.main.async {
                        manager.onToggle?()
                    }
                    // Consume the event so it doesn't pass through to other apps
                    return nil
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: selfPtr
        )

        guard let tap else {
            print("[HotkeyManager] Failed to create event tap. Accessibility permission may not be granted.")
            return
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[HotkeyManager] Global hotkey registered: Ctrl+Shift+Space")
    }

    /// Disables and removes the event tap.
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        print("[HotkeyManager] Global hotkey unregistered")
    }

    deinit {
        stop()
    }
}
