import SwiftUI
import AVFoundation
import whisper

/// Manages the menu bar icon state and orchestrates the full voice-to-text pipeline:
/// hotkey press -> record audio -> transcribe via whisper -> insert text at cursor.
///
/// Uses SwiftUI's ObservableObject so the MenuBarExtra icon updates reactively
/// across three states: idle, recording, and transcribing.
final class MenuBarManager: ObservableObject {
    /// Whether the app is currently recording audio.
    @Published var isRecording: Bool = false

    /// Whether the app is currently transcribing audio to text.
    @Published var isTranscribing: Bool = false

    /// Global hotkey manager — listens for Ctrl+Shift+Space system-wide.
    private let hotkeyManager = HotkeyManager()

    /// Audio capture manager — records microphone to WAV files.
    private let audioCaptureManager = AudioCaptureManager()

    /// Transcription manager — whisper.cpp context for speech-to-text.
    private var transcriptionManager: TranscriptionManager?

    /// Text insertion manager — inserts transcribed text at cursor via CGEvent.
    private let textInsertionManager = TextInsertionManager()

    /// Codeword detector — listens for the stop word during recording.
    private let codewordDetector = CodewordDetector()

    /// Floating overlay window — shows recording indicator without stealing focus.
    private let overlayWindow = RecordingOverlayWindow()

    /// Pre-warmed whisper context for codeword detection (tiny model).
    /// Created once at app launch and reused across all recording sessions,
    /// eliminating ~300-500ms context creation overhead per session.
    private var codewordContext: OpaquePointer?

    /// Centralized settings — codeword, autoEnter, insertionMethod, overlay toggle.
    /// Stored here so other plans (02, 03) can read settings from the pipeline orchestrator.
    let settings = SettingsManager.shared

    /// Whether microphone permission has been granted.
    private var microphonePermissionGranted: Bool = false

    /// SF Symbol name for the current state.
    /// - Idle: `mic` (outline microphone)
    /// - Recording: `mic.fill` (filled microphone)
    /// - Transcribing: `text.bubble` (text processing indicator)
    var statusIconName: String {
        isTranscribing ? "text.bubble" : (isRecording ? "mic.fill" : "mic")
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

        // Initialize transcription model asynchronously on launch
        Task { await self.initializeTranscription() }
    }

    /// Toggle recording state. Starts or stops audio capture.
    func toggleRecording() {
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }

    // MARK: - Transcription Initialization

    /// Downloads whisper models (if needed), creates transcription context, and pre-warms
    /// the codeword detection context from the tiny model.
    func initializeTranscription() async {
        do {
            // Download and load the base model for main transcription
            if !ModelManager.shared.isModelDownloaded {
                print("[MenuBarManager] Downloading whisper base model...")
                try await ModelManager.shared.downloadModel { progress in
                    print("[MenuBarManager] Base model download: \(Int(progress * 100))%")
                }
            }

            let manager = try TranscriptionManager.createContext(path: ModelManager.shared.modelPath)
            transcriptionManager = manager
            print("[MenuBarManager] Transcription model loaded successfully")

            // Download and pre-warm the tiny model for codeword detection
            if !ModelManager.shared.isTinyModelDownloaded {
                print("[MenuBarManager] Downloading whisper tiny model for codeword detection...")
                try await ModelManager.shared.downloadTinyModel { progress in
                    print("[MenuBarManager] Tiny model download: \(Int(progress * 100))%")
                }
            }

            var contextParams = whisper_context_default_params()
            contextParams.flash_attn = true

            if let ctx = whisper_init_from_file_with_params(ModelManager.shared.tinyModelPath, contextParams) {
                codewordContext = ctx
                print("[MenuBarManager] Codeword context pre-warmed (tiny model)")
            } else {
                print("[MenuBarManager] Warning: failed to create codeword context from tiny model")
            }
        } catch {
            print("[MenuBarManager] Failed to initialize transcription: \(error)")
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

        audioCaptureManager.codewordDetector = codewordDetector
        codewordDetector.onCodewordDetected = { [weak self] in
            DispatchQueue.main.async {
                self?.stopRecording()
            }
        }
        if let ctx = codewordContext {
            codewordDetector.start(context: ctx)
        } else {
            print("[MenuBarManager] Warning: codeword context not available, codeword detection disabled")
        }

        audioCaptureManager.startCapture()
        isRecording = true

        if settings.showOverlay {
            overlayWindow.show()
        }

        print("[MenuBarManager] Recording started")
    }

    private func stopRecording() {
        overlayWindow.hide()

        codewordDetector.stop()
        audioCaptureManager.codewordDetector = nil

        let url = audioCaptureManager.stopCapture()
        isRecording = false

        guard let url = url else {
            print("[MenuBarManager] Recording stopped but no file produced")
            return
        }

        guard transcriptionManager != nil else {
            print("[MenuBarManager] Warning: transcription model not loaded yet — audio file discarded")
            return
        }

        // Enter transcribing state and process the recording
        DispatchQueue.main.async {
            self.isTranscribing = true
        }
        Task { await self.processRecording(url: url) }
    }

    /// Transcribes the audio file and inserts the resulting text at the cursor.
    private func processRecording(url: URL) async {
        do {
            let text = try await transcriptionManager!.transcribe(audioURL: url)

            DispatchQueue.main.async {
                self.isTranscribing = false

                var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

                // Strip codeword from end of transcription
                let codeword = SettingsManager.shared.codeword.lowercased()
                if !codeword.isEmpty {
                    // Handle "over." with trailing punctuation first (longer match)
                    let codewordWithPunctuation = codeword + "."
                    if trimmed.lowercased().hasSuffix(codewordWithPunctuation) {
                        trimmed = String(trimmed.dropLast(codewordWithPunctuation.count))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if trimmed.lowercased().hasSuffix(codeword) {
                        trimmed = String(trimmed.dropLast(codeword.count))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }

                if !trimmed.isEmpty {
                    self.textInsertionManager.insertText(trimmed)
                    print("[MenuBarManager] Inserted text: \(trimmed)")
                } else {
                    print("[MenuBarManager] Transcription returned empty text")
                }
            }

            // Clean up temporary WAV file
            try? FileManager.default.removeItem(at: url)

        } catch {
            DispatchQueue.main.async {
                self.isTranscribing = false
            }
            print("[MenuBarManager] Transcription error: \(error)")
        }
    }

    deinit {
        hotkeyManager.stop()
        overlayWindow.hide()
        codewordDetector.shutdown()
        if isRecording {
            audioCaptureManager.stopCapture()
        }
        if let ctx = codewordContext {
            whisper_free(ctx)
            codewordContext = nil
        }
    }
}
