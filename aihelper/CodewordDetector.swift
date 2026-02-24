import Foundation
import whisper

/// Detects a spoken codeword during live recording using periodic whisper transcription
/// of a rolling audio buffer.
///
/// Architecture: Maintains a rolling buffer of recent audio (~2 seconds at 16kHz).
/// Every ~1 second, runs a whisper transcription pass on the buffer and checks if
/// the configured codeword appears in the output. When detected, fires the
/// `onCodewordDetected` callback so the recording pipeline can stop automatically.
///
/// The whisper context is owned externally (pre-warmed at app launch) and passed in
/// via `start(context:)`. This eliminates ~300-500ms context creation per recording session.
///
/// This is a class (not actor) because `appendAudio` is called synchronously from the
/// audio tap callback. Thread safety is handled via a serial DispatchQueue.
final class CodewordDetector {

    /// Called when the codeword is detected in audio. Called on background thread.
    var onCodewordDetected: (() -> Void)?

    /// Rolling buffer of 16kHz mono Float samples.
    private var audioBuffer: [Float] = []

    /// Maximum buffer size: ~2 seconds at 16kHz (a single codeword is well under 2s).
    private let maxBufferSamples = 16000 * 2

    /// Whisper context for codeword detection (externally owned, reused across sessions).
    private var whisperContext: OpaquePointer?

    /// Timer for periodic transcription checks.
    private var detectionTimer: DispatchSourceTimer?

    /// Whether detection is currently active.
    private(set) var isActive: Bool = false

    /// Serial queue for buffer access and transcription.
    private let queue = DispatchQueue(label: "com.aihelper.codeword", qos: .userInteractive)

    /// Pre-allocated C string for the English language hint, avoiding dangling pointer issues.
    /// Codeword "over" is English -- explicit hint skips auto-detect (~200ms saved per check).
    private let languageHint: UnsafeMutablePointer<CChar>

    init() {
        languageHint = strdup("en")!
    }

    deinit {
        free(languageHint)
    }

    // MARK: - Lifecycle

    /// Starts codeword detection using a pre-warmed whisper context.
    ///
    /// The context is owned externally (by MenuBarManager) and reused across recording
    /// sessions. This eliminates ~300-500ms context creation overhead per session.
    ///
    /// - Parameter context: Pre-created whisper context (from tiny model with flash_attn).
    func start(context: OpaquePointer) {
        queue.async { [self] in
            guard !isActive else { return }

            whisperContext = context
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

            print("[CodewordDetector] Started with pre-warmed context")
        }
    }

    /// Stops codeword detection, cancels timer, and clears buffer.
    ///
    /// Does NOT free the whisper context -- it is owned externally and will be
    /// reused across recording sessions. Call `shutdown()` on app termination.
    ///
    /// Safe to call multiple times.
    func stop() {
        queue.async { [self] in
            guard isActive else { return }
            isActive = false

            detectionTimer?.cancel()
            detectionTimer = nil

            audioBuffer.removeAll()
            whisperContext = nil  // Release reference, don't free (externally owned)

            print("[CodewordDetector] Stopped")
        }
    }

    /// Frees the whisper context. Called only on app termination.
    ///
    /// After calling this, the context pointer is invalid and must not be reused.
    func shutdown() {
        queue.sync {
            isActive = false
            detectionTimer?.cancel()
            detectionTimer = nil
            audioBuffer.removeAll()
            // Context is freed by the owner (MenuBarManager), just nil our reference
            whisperContext = nil
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
    /// Optimized params: explicit English language, reduced audio_ctx (256), temperature 0,
    /// adaptive thread count.
    private func checkForCodeword() {
        guard isActive, let ctx = whisperContext else { return }

        // Need at least 0.3 seconds of audio (4800 samples at 16kHz)
        guard audioBuffer.count >= 4800 else { return }

        // Configure whisper for fast, single-pass detection
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.language = UnsafePointer(languageHint)  // English hint -- skip auto-detect
        params.n_threads = Int32(max(4, ProcessInfo.processInfo.processorCount - 2))
        params.no_context = true
        params.single_segment = true
        params.audio_ctx = 256  // 256 * ~10ms = 2.56s coverage, sufficient for 2s buffer
        params.temperature = 0.0  // Deterministic greedy for single known word

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
            // Do NOT free context -- it's externally owned and will be reused
            whisperContext = nil
            callback?()
        }
    }
}
