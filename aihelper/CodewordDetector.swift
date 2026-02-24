import Foundation
import whisper

/// Detects a spoken codeword during live recording using periodic whisper transcription
/// of a rolling audio buffer.
///
/// Architecture: Maintains a rolling buffer of recent audio (~4 seconds at 16kHz).
/// Every ~2 seconds, runs a whisper transcription pass on the buffer and checks if
/// the configured codeword appears in the output. When detected, fires the
/// `onCodewordDetected` callback so the recording pipeline can stop automatically.
///
/// This is a class (not actor) because `appendAudio` is called synchronously from the
/// audio tap callback. Thread safety is handled via a serial DispatchQueue.
final class CodewordDetector {

    /// Called when the codeword is detected in audio. Called on background thread.
    var onCodewordDetected: (() -> Void)?

    /// Rolling buffer of 16kHz mono Float samples.
    private var audioBuffer: [Float] = []

    /// Maximum buffer size: ~2 seconds at 16kHz (short buffer for fast detection).
    private let maxBufferSamples = 16000 * 2

    /// Whisper context for codeword detection (separate from main transcription context).
    private var whisperContext: OpaquePointer?

    /// Timer for periodic transcription checks.
    private var detectionTimer: DispatchSourceTimer?

    /// Whether detection is currently active.
    private(set) var isActive: Bool = false

    /// Serial queue for buffer access and transcription.
    private let queue = DispatchQueue(label: "com.aihelper.codeword", qos: .userInteractive)

    // MARK: - Lifecycle

    /// Starts codeword detection by creating a whisper context and scheduling periodic checks.
    ///
    /// Creates a separate (lightweight) whisper context that reuses the same model file.
    /// The OS memory-maps the model weights so the overhead is minimal (~20MB).
    ///
    /// - Parameter modelPath: Absolute path to the whisper model file (e.g. ggml-base.bin).
    func start(modelPath: String) {
        queue.async { [self] in
            guard !isActive else { return }

            // Create whisper context with Metal acceleration
            var contextParams = whisper_context_default_params()
            contextParams.flash_attn = true

            guard let ctx = whisper_init_from_file_with_params(modelPath, contextParams) else {
                print("[CodewordDetector] Failed to create whisper context from \(modelPath)")
                return
            }

            whisperContext = ctx
            audioBuffer.removeAll()
            isActive = true

            // Schedule periodic detection every 1 second
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
            timer.setEventHandler { [weak self] in
                self?.checkForCodeword()
            }
            timer.resume()
            detectionTimer = timer

            print("[CodewordDetector] Started — checking every 2s")
        }
    }

    /// Stops codeword detection, cancels timer, clears buffer, and frees whisper context.
    ///
    /// Safe to call multiple times.
    func stop() {
        queue.async { [self] in
            guard isActive else { return }
            isActive = false

            detectionTimer?.cancel()
            detectionTimer = nil

            audioBuffer.removeAll()

            if let ctx = whisperContext {
                whisper_free(ctx)
                whisperContext = nil
            }

            print("[CodewordDetector] Stopped")
        }
    }

    // MARK: - Audio Input

    /// Appends audio samples to the rolling buffer.
    ///
    /// Called from the audio tap callback with converted Float samples.
    /// Trims from the front if buffer exceeds maxBufferSamples to keep only recent audio.
    ///
    /// - Parameter samples: Array of Float samples in [-1.0, 1.0] range at 16kHz.
    func appendAudio(_ samples: [Float]) {
        queue.async { [self] in
            guard isActive else { return }

            audioBuffer.append(contentsOf: samples)

            // Trim from front to keep only the most recent audio
            if audioBuffer.count > maxBufferSamples {
                audioBuffer.removeFirst(audioBuffer.count - maxBufferSamples)
            }
        }
    }

    // MARK: - Detection

    /// Runs whisper transcription on the current buffer and checks for the codeword.
    ///
    /// Called on the serial queue by the detection timer.
    private func checkForCodeword() {
        guard isActive, let ctx = whisperContext else { return }

        // Need at least 0.5 seconds of audio (8000 samples at 16kHz)
        guard audioBuffer.count >= 8000 else { return }

        // Configure whisper for fast, single-pass detection
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.language = nil  // Auto-detect (German + English)
        params.n_threads = 6
        params.no_context = true
        params.single_segment = true
        params.audio_ctx = 512  // Limit audio context for shorter processing

        // Run transcription on buffer contents
        let result = audioBuffer.withUnsafeBufferPointer { bufferPointer in
            whisper_full(ctx, params, bufferPointer.baseAddress, Int32(bufferPointer.count))
        }

        guard result == 0 else {
            print("[CodewordDetector] Whisper pass failed with code \(result)")
            return
        }

        // Collect transcribed text from all segments
        let segmentCount = whisper_full_n_segments(ctx)
        var text = ""
        for i in 0..<segmentCount {
            if let segmentText = whisper_full_get_segment_text(ctx, i) {
                text += String(cString: segmentText)
            }
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let codeword = SettingsManager.shared.codeword
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !codeword.isEmpty, !trimmedText.isEmpty else { return }

        // Check if transcription contains the codeword (case-insensitive, tolerant)
        if trimmedText.contains(codeword) {
            print("[CodewordDetector] Codeword '\(codeword)' detected in: \(trimmedText)")
            let callback = onCodewordDetected
            // Stop detection to prevent multiple triggers, then fire callback
            isActive = false
            detectionTimer?.cancel()
            detectionTimer = nil
            audioBuffer.removeAll()
            if let ctx = whisperContext {
                whisper_free(ctx)
                whisperContext = nil
            }
            callback?()
        }
    }
}
