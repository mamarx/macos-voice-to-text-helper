import SwiftUI
import AVFoundation

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

    /// Downloads the whisper model (if needed) and creates the transcription context.
    func initializeTranscription() async {
        do {
            if !ModelManager.shared.isModelDownloaded {
                print("[MenuBarManager] Downloading whisper model...")
                try await ModelManager.shared.downloadModel { progress in
                    print("[MenuBarManager] Model download: \(Int(progress * 100))%")
                }
            }

            let manager = try TranscriptionManager.createContext(path: ModelManager.shared.modelPath)
            transcriptionManager = manager
            print("[MenuBarManager] Transcription model loaded successfully")
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
        codewordDetector.start(modelPath: ModelManager.shared.modelPath)

        audioCaptureManager.startCapture()
        isRecording = true
        print("[MenuBarManager] Recording started")
    }

    private func stopRecording() {
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
        if isRecording {
            audioCaptureManager.stopCapture()
        }
    }
}
