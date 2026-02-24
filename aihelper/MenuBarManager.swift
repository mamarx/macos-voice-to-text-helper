import SwiftUI
import AVFoundation

/// Manages the menu bar icon state, reflecting idle vs recording status.
///
/// Uses SwiftUI's ObservableObject so the MenuBarExtra icon updates reactively.
/// Owns the HotkeyManager and AudioCaptureManager, orchestrating:
/// hotkey press -> toggle recording -> update icon.
final class MenuBarManager: ObservableObject {
    /// Whether the app is currently recording audio.
    @Published var isRecording: Bool = false

    /// Global hotkey manager — listens for Ctrl+Shift+Space system-wide.
    private let hotkeyManager = HotkeyManager()

    /// Audio capture manager — records microphone to WAV files.
    private let audioCaptureManager = AudioCaptureManager()

    /// Whether microphone permission has been granted.
    private var microphonePermissionGranted: Bool = false

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

        // Pre-check microphone permission status
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphonePermissionGranted = (status == .authorized)
    }

    /// Toggle recording state. Starts or stops audio capture.
    func toggleRecording() {
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }

    // MARK: - Private

    private func startRecording() {
        // Request microphone permission if not yet granted
        guard microphonePermissionGranted else {
            AudioCaptureManager.requestMicrophonePermission { [weak self] granted in
                guard let self = self else { return }
                self.microphonePermissionGranted = granted
                if granted {
                    self.startRecording()
                } else {
                    print("[MenuBarManager] Microphone permission denied — cannot record")
                }
            }
            return
        }

        audioCaptureManager.startCapture()
        isRecording = true
        print("[MenuBarManager] Recording started")
    }

    private func stopRecording() {
        let url = audioCaptureManager.stopCapture()
        isRecording = false
        if let url = url {
            print("Recording saved to: \(url.path)")
        } else {
            print("[MenuBarManager] Recording stopped but no file produced")
        }
    }

    deinit {
        hotkeyManager.stop()
        if isRecording {
            audioCaptureManager.stopCapture()
        }
    }
}
