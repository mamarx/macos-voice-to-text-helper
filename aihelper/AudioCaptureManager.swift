import AVFoundation

/// Captures microphone audio and writes it to a WAV file.
///
/// Uses AVAudioEngine to capture from the default input device,
/// converts to 16kHz mono 16-bit PCM (the format whisper.cpp expects),
/// and writes to a temporary WAV file via AVAudioFile.
final class AudioCaptureManager {

    /// Whether audio capture is currently active.
    private(set) var isCapturing: Bool = false

    /// URL of the most recent completed recording.
    private(set) var lastRecordingURL: URL?

    /// The audio engine used for microphone capture.
    private let audioEngine = AVAudioEngine()

    /// The output file being written to during capture.
    private var audioFile: AVAudioFile?

    /// Target audio format: 16kHz, mono, 16-bit integer PCM.
    /// This is the format whisper.cpp expects in Phase 2.
    private var targetFormat: AVAudioFormat? {
        AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )
    }

    // MARK: - Microphone Permission

    /// Requests microphone permission asynchronously.
    /// Calls the completion handler on the main thread with the result.
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            print("[AudioCaptureManager] Microphone permission denied or restricted")
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // MARK: - Start / Stop Capture

    /// Starts capturing audio from the microphone.
    ///
    /// Creates a WAV file in the temporary directory and begins writing
    /// audio buffers converted to 16kHz mono 16-bit PCM.
    func startCapture() {
        guard !isCapturing else {
            print("[AudioCaptureManager] Already capturing")
            return
        }

        guard let targetFormat = targetFormat else {
            print("[AudioCaptureManager] Failed to create target audio format")
            return
        }

        // Create output file path
        let timestamp = Date().timeIntervalSince1970
        let fileName = "aihelper_recording_\(timestamp).wav"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            // Create the output AVAudioFile with our target format.
            // AVAudioFile handles WAV header creation automatically.
            audioFile = try AVAudioFile(
                forWriting: fileURL,
                settings: targetFormat.settings,
                commonFormat: .pcmFormatInt16,
                interleaved: true
            )
        } catch {
            print("[AudioCaptureManager] Failed to create audio file: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        // Validate hardware format
        guard hardwareFormat.sampleRate > 0, hardwareFormat.channelCount > 0 else {
            print("[AudioCaptureManager] Invalid hardware audio format: \(hardwareFormat)")
            audioFile = nil
            return
        }

        // Create converter from hardware format to target format
        guard let converter = AVAudioConverter(from: hardwareFormat, to: targetFormat) else {
            print("[AudioCaptureManager] Failed to create audio converter from \(hardwareFormat) to \(targetFormat)")
            audioFile = nil
            return
        }

        // Install tap on input node to receive audio buffers
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] (buffer, time) in
            guard let self = self, let audioFile = self.audioFile else { return }

            // Calculate how many frames we need in the target format
            let ratio = targetFormat.sampleRate / hardwareFormat.sampleRate
            let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
                return
            }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if status == .error {
                if let error = error {
                    print("[AudioCaptureManager] Conversion error: \(error)")
                }
                return
            }

            // Write converted buffer to file
            do {
                try audioFile.write(from: convertedBuffer)
            } catch {
                print("[AudioCaptureManager] Write error: \(error)")
            }
        }

        do {
            try audioEngine.start()
            isCapturing = true
            print("[AudioCaptureManager] Capture started -> \(fileURL.path)")
        } catch {
            print("[AudioCaptureManager] Failed to start audio engine: \(error)")
            inputNode.removeTap(onBus: 0)
            audioFile = nil
        }
    }

    /// Stops capturing audio and returns the URL of the completed recording.
    @discardableResult
    func stopCapture() -> URL? {
        guard isCapturing else {
            print("[AudioCaptureManager] Not currently capturing")
            return nil
        }

        // Remove tap and stop engine
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        // Close the audio file by releasing it
        let fileURL = audioFile?.url
        audioFile = nil
        isCapturing = false

        if let url = fileURL {
            lastRecordingURL = url
            print("[AudioCaptureManager] Capture stopped. File: \(url.path)")
            return url
        }

        return nil
    }
}
