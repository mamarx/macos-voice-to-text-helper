import Foundation
import whisper

/// Actor-based wrapper around the whisper C API for local speech-to-text transcription.
///
/// Uses the actor pattern (following the whisper.swiftui example) to prevent concurrent
/// access to the whisper context pointer. Supports automatic language detection for
/// both German and English speech.
actor TranscriptionManager {

    /// The opaque whisper context pointer.
    private var context: OpaquePointer

    /// Private initializer accepting a pre-created whisper context.
    private init(context: OpaquePointer) {
        self.context = context
    }

    deinit {
        whisper_free(context)
    }

    // MARK: - Factory

    /// Creates a TranscriptionManager by loading a whisper model from the given file path.
    ///
    /// Enables flash attention for Metal acceleration on Apple Silicon.
    ///
    /// - Parameter path: Absolute path to the whisper model file (e.g. ggml-base.bin).
    /// - Returns: A configured TranscriptionManager ready for transcription.
    /// - Throws: If the model file cannot be loaded.
    static func createContext(path: String) throws -> TranscriptionManager {
        var params = whisper_context_default_params()
        params.flash_attn = true

        guard let ctx = whisper_init_from_file_with_params(path, params) else {
            throw TranscriptionError.failedToLoadModel(path: path)
        }

        return TranscriptionManager(context: ctx)
    }

    // MARK: - Transcription

    /// Transcribes speech from a WAV audio file to text.
    ///
    /// The WAV file must be 16kHz, mono, 16-bit PCM (the format produced by AudioCaptureManager).
    /// Language is auto-detected (supports German and English without manual selection).
    ///
    /// - Parameter audioURL: URL of the WAV file to transcribe.
    /// - Returns: The transcribed text string.
    /// - Throws: If the file cannot be read or transcription fails.
    func transcribe(audioURL: URL) async throws -> String {
        // Read the WAV file
        let data = try Data(contentsOf: audioURL)

        // Skip the 44-byte WAV header and convert Int16 PCM samples to Float [-1.0, 1.0]
        guard data.count > 44 else {
            throw TranscriptionError.invalidAudioFile(reason: "File too small to contain valid WAV data")
        }

        let audioData = data.dropFirst(44)
        let sampleCount = audioData.count / MemoryLayout<Int16>.size

        var samples = [Float](repeating: 0, count: sampleCount)
        audioData.withUnsafeBytes { rawBuffer in
            let int16Buffer = rawBuffer.bindMemory(to: Int16.self)
            for i in 0..<sampleCount {
                samples[i] = Float(int16Buffer[i]) / 32768.0
            }
        }

        // Configure whisper parameters
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.language = nil  // Auto-detect language (German + English)
        params.n_threads = Int32(max(1, min(8, ProcessInfo.processInfo.processorCount - 2)))
        params.no_context = true
        params.single_segment = false

        // Run transcription
        let result = samples.withUnsafeBufferPointer { bufferPointer in
            whisper_full(context, params, bufferPointer.baseAddress, Int32(bufferPointer.count))
        }

        guard result == 0 else {
            throw TranscriptionError.transcriptionFailed(code: Int(result))
        }

        // Collect transcribed text from all segments
        let segmentCount = whisper_full_n_segments(context)
        var text = ""
        for i in 0..<segmentCount {
            if let segmentText = whisper_full_get_segment_text(context, i) {
                text += String(cString: segmentText)
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case failedToLoadModel(path: String)
    case invalidAudioFile(reason: String)
    case transcriptionFailed(code: Int)

    var errorDescription: String? {
        switch self {
        case .failedToLoadModel(let path):
            return "Failed to load whisper model at: \(path)"
        case .invalidAudioFile(let reason):
            return "Invalid audio file: \(reason)"
        case .transcriptionFailed(let code):
            return "Whisper transcription failed with code: \(code)"
        }
    }
}
