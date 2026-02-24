import Foundation

/// Manages the whisper model file lifecycle: download, storage, and path resolution.
///
/// The model is downloaded once from HuggingFace on first launch and stored in
/// Application Support/aihelper/models/. This is the ONLY network call in the
/// entire app -- all transcription is fully local after model setup.
final class ModelManager {

    /// Shared singleton instance.
    static let shared = ModelManager()

    /// Download URL for the ggml-base whisper model.
    ///
    /// Using base (not tiny) because:
    /// - Significantly better multi-language accuracy (required for German + English)
    /// - On Apple Silicon with Metal acceleration, base model still transcribes
    ///   under 3 seconds for 30s audio
    private let modelDownloadURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin")!

    /// The model filename.
    private let modelFileName = "ggml-base.bin"

    private init() {}

    // MARK: - Path Management

    /// Directory where whisper models are stored.
    ///
    /// Located at ~/Library/Application Support/aihelper/models/.
    /// Creates the directory if it does not exist.
    var modelDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("aihelper/models")

        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }

        return modelsDir
    }

    /// Full path string to the ggml-base.bin model file.
    ///
    /// Used by TranscriptionManager.createContext(path:) to initialize whisper.
    var modelPath: String {
        modelDirectoryURL.appendingPathComponent(modelFileName).path
    }

    /// Whether the model file has already been downloaded and exists on disk.
    var isModelDownloaded: Bool {
        FileManager.default.fileExists(atPath: modelPath)
    }

    // MARK: - Download

    /// Downloads the whisper model from HuggingFace if not already present.
    ///
    /// Uses streaming download with progress reporting. The model file is ~148MB.
    /// Downloads to a temporary file first, then moves atomically to the final path.
    ///
    /// - Parameter progress: Callback reporting download progress from 0.0 to 1.0.
    /// - Throws: If the download or file operations fail.
    func downloadModel(progress: @escaping (Double) -> Void) async throws {
        // Skip if already downloaded
        guard !isModelDownloaded else {
            progress(1.0)
            return
        }

        let finalURL = modelDirectoryURL.appendingPathComponent(modelFileName)
        let tempURL = modelDirectoryURL.appendingPathComponent(modelFileName + ".download")

        // Clean up any previous incomplete download
        try? FileManager.default.removeItem(at: tempURL)

        do {
            let (asyncBytes, response) = try await URLSession.shared.bytes(from: modelDownloadURL)

            // Get expected content length for progress calculation
            let expectedLength = response.expectedContentLength
            var receivedLength: Int64 = 0

            // Stream bytes to temporary file
            var data = Data()
            data.reserveCapacity(expectedLength > 0 ? Int(expectedLength) : 150_000_000)

            for try await byte in asyncBytes {
                data.append(byte)
                receivedLength += 1

                // Report progress periodically (every ~1MB to avoid excessive callbacks)
                if receivedLength % (1024 * 1024) == 0, expectedLength > 0 {
                    let fraction = Double(receivedLength) / Double(expectedLength)
                    progress(min(fraction, 0.99))
                }
            }

            // Write to temp file
            try data.write(to: tempURL)

            // Move atomically to final path
            try FileManager.default.moveItem(at: tempURL, to: finalURL)

            progress(1.0)
            print("[ModelManager] Model downloaded successfully (\(data.count) bytes)")

        } catch {
            // Clean up temp file on failure
            try? FileManager.default.removeItem(at: tempURL)
            throw ModelDownloadError.downloadFailed(underlying: error)
        }
    }
}

// MARK: - Errors

enum ModelDownloadError: LocalizedError {
    case downloadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let underlying):
            return "Failed to download whisper model: \(underlying.localizedDescription)"
        }
    }
}
