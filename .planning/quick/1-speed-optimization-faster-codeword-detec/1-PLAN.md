---
phase: quick-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - aihelper/CodewordDetector.swift
  - aihelper/ModelManager.swift
  - aihelper/TranscriptionManager.swift
  - aihelper/AudioCaptureManager.swift
  - aihelper/MenuBarManager.swift
autonomous: true
requirements: [SPEED-01]

must_haves:
  truths:
    - "Codeword detection responds noticeably faster (under 500ms per check vs current ~800ms+)"
    - "Main transcription completes faster by skipping disk I/O and auto-detect overhead"
    - "App launch pre-warms codeword context so first recording has zero context-creation delay"
  artifacts:
    - path: "aihelper/CodewordDetector.swift"
      provides: "Optimized codeword detection with tiny model, pre-warmed context, tuned params"
    - path: "aihelper/ModelManager.swift"
      provides: "Dual model management (tiny for codeword, base for transcription)"
    - path: "aihelper/TranscriptionManager.swift"
      provides: "In-memory transcription from Float samples, explicit language hint"
    - path: "aihelper/AudioCaptureManager.swift"
      provides: "In-memory audio buffer alongside WAV file for direct transcription"
    - path: "aihelper/MenuBarManager.swift"
      provides: "Pre-warmed codeword context, in-memory transcription pipeline"
  key_links:
    - from: "aihelper/MenuBarManager.swift"
      to: "aihelper/CodewordDetector.swift"
      via: "pre-warmed context passed at init, not created per-session"
      pattern: "codewordDetector\\.start.*context"
    - from: "aihelper/AudioCaptureManager.swift"
      to: "aihelper/TranscriptionManager.swift"
      via: "accumulated Float samples passed directly, no disk round-trip"
      pattern: "transcribe.*samples|audioSamples"
---

<objective>
Optimize the full voice-to-text pipeline for speed. The user reports the app is noticeably slower than competitors like Wispr Flow. This plan targets three bottlenecks: (1) codeword detection uses the heavy base model when tiny suffices, (2) whisper context is recreated every recording session, (3) main transcription reads from disk when samples are already in memory.

Purpose: Achieve near-instant codeword detection and faster post-recording transcription.
Output: Optimized CodewordDetector, TranscriptionManager, AudioCaptureManager, ModelManager, MenuBarManager.
</objective>

<execution_context>
@/Users/mm/.claude/get-shit-done/workflows/execute-plan.md
@/Users/mm/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@aihelper/CodewordDetector.swift
@aihelper/TranscriptionManager.swift
@aihelper/AudioCaptureManager.swift
@aihelper/ModelManager.swift
@aihelper/MenuBarManager.swift
@aihelper/SettingsManager.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Use ggml-tiny model for codeword detection + pre-warm context</name>
  <files>
    aihelper/ModelManager.swift
    aihelper/CodewordDetector.swift
    aihelper/MenuBarManager.swift
  </files>
  <action>
**ModelManager.swift -- Add tiny model support:**
- Add a second model URL for ggml-tiny.bin: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin` (~75MB)
- Add `tinyModelFileName = "ggml-tiny.bin"` and corresponding `tinyModelPath` computed property
- Add `isTinyModelDownloaded` computed property
- Add `downloadTinyModel(progress:)` async method (same pattern as existing downloadModel)
- Keep the existing base model for main transcription unchanged

**CodewordDetector.swift -- Pre-warm context + use tiny model + optimize params:**
- Change `start(modelPath:)` to `start(context:)` that accepts a pre-created OpaquePointer instead of creating one each time. This eliminates ~300-500ms context creation per recording session.
- Remove context creation from `start()` -- it now just stores the passed context, clears buffer, starts timer.
- Change `stop()` to NOT free the whisper context (it's owned externally now, will be reused across sessions). Only cancel timer + clear buffer + set isActive=false.
- Remove `whisper_free(ctx)` from the codeword-detected callback path as well -- just stop detection, don't destroy context.
- Add a new `shutdown()` method that DOES free the context (called only on app termination).
- Reduce `maxBufferSamples` from `16000 * 3` (3s) to `16000 * 2` (2s) -- a single codeword is well under 2 seconds.
- Optimize whisper params in `checkForCodeword()`:
  - Set `params.language` to `UnsafePointer<CChar>(("en" as NSString).utf8String)` -- the codeword "over" is English, skip auto-detect (~200ms saved per check). Use a stored C string pointer (instance property `private let languageHint: UnsafeMutablePointer<CChar>`) allocated in init to avoid dangling pointer issues. Allocate with strdup("en") and free in deinit/shutdown.
  - Reduce `params.audio_ctx` from 512 to 256 -- for a 2-second buffer of a single word, 256 is sufficient (each audio_ctx unit = ~10ms of audio, 256 = 2.56s coverage).
  - Set `params.temperature = 0.0` -- deterministic greedy for single known word.
  - Set `params.n_threads` to `Int32(max(4, ProcessInfo.processInfo.processorCount - 2))` instead of hardcoded 6.
- Reduce minimum audio threshold from 8000 samples (0.5s) to 4800 samples (0.3s).

**MenuBarManager.swift -- Pre-warm codeword context at launch:**
- Add a private property `codewordContext: OpaquePointer?` to hold the pre-warmed tiny model context.
- In `initializeTranscription()`, after loading the base model, also:
  1. Download tiny model if needed via `ModelManager.shared.downloadTinyModel`
  2. Create a whisper context from the tiny model path with `flash_attn = true`
  3. Store in `self.codewordContext`
- In `startRecording()`, pass the pre-warmed context: `codewordDetector.start(context: codewordContext!)` instead of `codewordDetector.start(modelPath:)`.
- In `deinit`, free the codeword context with `whisper_free(codewordContext)`.
  </action>
  <verify>
    <automated>cd /Users/mm/Dev/aihelper && swift build 2>&1 | tail -5</automated>
    <manual>Launch app, trigger recording with Ctrl+Shift+Space, say "over" -- codeword should be detected noticeably faster than before.</manual>
  </verify>
  <done>
    - Codeword detection uses ggml-tiny (~5x faster inference than base)
    - Whisper context is created once at app launch, reused across all recording sessions
    - Detection params optimized: explicit English language, reduced audio_ctx, deterministic temperature
    - Buffer reduced from 3s to 2s, minimum threshold from 0.5s to 0.3s
    - App builds without errors
  </done>
</task>

<task type="auto">
  <name>Task 2: In-memory transcription pipeline (skip disk I/O)</name>
  <files>
    aihelper/AudioCaptureManager.swift
    aihelper/TranscriptionManager.swift
    aihelper/MenuBarManager.swift
  </files>
  <action>
**AudioCaptureManager.swift -- Accumulate Float samples in memory:**
- Add a property `private var accumulatedSamples: [Float] = []` to collect all audio during recording.
- In the audio tap callback, after writing to the AVAudioFile, also accumulate the Float samples in `accumulatedSamples`. The Float conversion is already happening for the codeword detector -- reuse that same conversion. Restructure the tap callback to:
  1. Convert Int16 to Float once
  2. Append to `accumulatedSamples`
  3. Forward to codeword detector (if active)
  4. (Keep writing Int16 to AVAudioFile as before, as a backup/debug artifact)
- Add a method `func getAccumulatedSamples() -> [Float]` that returns the accumulated samples.
- In `stopCapture()`, do NOT clear `accumulatedSamples` yet -- let the caller retrieve them first.
- Add `func clearAccumulatedSamples()` to be called after transcription completes.
- In `startCapture()`, clear `accumulatedSamples` at the beginning.

**TranscriptionManager.swift -- Add in-memory transcription method:**
- Add a new method `func transcribe(samples: [Float]) async throws -> String` that accepts Float samples directly.
- This method skips WAV file reading and Int16->Float conversion entirely -- the samples are already in the right format.
- Configure whisper params same as existing but with one optimization: set `params.language` to a pointer to "de" (German hint -- since the main use case is German dictation, this saves auto-detect time). Allocate the C string safely. If the user speaks English, whisper will still handle it, but the hint biases toward faster German detection.
- Actually, to be safe and support both languages, keep `params.language = nil` for main transcription. The auto-detect cost is acceptable here since transcription is a one-time post-recording operation, not a periodic check like codeword detection.

**MenuBarManager.swift -- Wire in-memory pipeline:**
- In `stopRecording()`, retrieve accumulated samples: `let samples = audioCaptureManager.getAccumulatedSamples()`
- Pass samples to `processRecording(samples:url:)` (keep URL for cleanup).
- Update `processRecording` to call `transcriptionManager.transcribe(samples: samples)` instead of `transcribe(audioURL:)`.
- After transcription completes, call `audioCaptureManager.clearAccumulatedSamples()`.
- Clean up the WAV file as before.
- Streamline the async flow: remove unnecessary `DispatchQueue.main.async` wrapping around the Task launch. Set `isTranscribing = true` directly (already on main thread from `stopRecording`), then `Task { await processRecording(...) }`.
  </action>
  <verify>
    <automated>cd /Users/mm/Dev/aihelper && swift build 2>&1 | tail -5</automated>
    <manual>Record speech with Ctrl+Shift+Space, stop with codeword or hotkey -- text should appear faster than before since no WAV file read is needed.</manual>
  </verify>
  <done>
    - Audio samples accumulated in memory during recording alongside WAV file write
    - TranscriptionManager accepts Float samples directly, skipping disk I/O and format conversion
    - Full pipeline: record -> accumulate samples in memory -> pass directly to whisper -> insert text
    - WAV file still written as backup but not read back for transcription
    - Estimated savings: 50-200ms depending on recording length (disk read + Int16->Float conversion eliminated)
    - App builds without errors
  </done>
</task>

</tasks>

<verification>
1. `swift build` completes without errors
2. App launches, menu bar icon appears
3. Ctrl+Shift+Space starts recording (overlay shows if enabled)
4. Saying "over" triggers codeword detection and stops recording
5. Transcribed text is inserted at cursor position
6. Console logs show "[CodewordDetector] Started" with pre-warmed context (no "creating whisper context" per session)
7. Second recording session starts immediately without context creation delay
</verification>

<success_criteria>
- Codeword detection uses ggml-tiny model (~5x faster per inference pass)
- Whisper context pre-warmed at launch, reused across sessions (zero per-session overhead)
- Detection interval tuned: 2s buffer, 256 audio_ctx, explicit language, temperature 0
- Main transcription reads from memory instead of disk (eliminates WAV read + conversion)
- All existing functionality preserved: hotkey, overlay, settings, text insertion
- Clean build with zero warnings related to these changes
</success_criteria>

<output>
After completion, create `.planning/quick/1-speed-optimization-faster-codeword-detec/1-SUMMARY.md`
</output>
