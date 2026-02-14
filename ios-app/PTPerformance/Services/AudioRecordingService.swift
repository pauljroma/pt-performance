import Foundation
import AVFoundation
import Speech
import SwiftUI

// MARK: - Audio Recording Service

/// Service that handles audio recording and speech-to-text transcription
@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isTranscribing = false
    @Published var currentTranscription = ""
    @Published var recordingDuration: TimeInterval = 0
    @Published var errorMessage: String?

    // MARK: - Audio Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?

    // MARK: - Speech Recognition Properties

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    override init() {
        super.init()
        setupSpeechRecognizer()
    }

    // MARK: - Setup

    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Permissions

    /// Request microphone and speech recognition permissions
    func requestPermissions() async -> Bool {
        // Request microphone permission
        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else {
            errorMessage = "Microphone permission denied"
            return false
        }

        // Request speech recognition permission
        let speechGranted = await requestSpeechRecognitionPermission()
        guard speechGranted else {
            errorMessage = "Speech recognition permission denied"
            return false
        }

        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Recording Controls

    /// Start recording audio with live transcription
    func startRecording() async throws {
        // Request permissions first
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            throw RecordingError.permissionDenied
        }

        // Setup audio session
        try setupAudioSession()

        // Create recording URL
        let recordingURL = try createRecordingURL()

        // Setup audio recorder
        try setupAudioRecorder(url: recordingURL)

        // Start recording
        guard audioRecorder?.record() == true else {
            throw RecordingError.recordingFailed
        }

        isRecording = true
        recordingStartTime = Date()
        startRecordingTimer()

        // Start live transcription
        try await startLiveTranscription()
    }

    /// Stop recording and finalize transcription
    func stopRecording() async -> (url: URL?, transcription: String, duration: TimeInterval) {
        isRecording = false
        stopRecordingTimer()

        // Stop audio recorder
        audioRecorder?.stop()
        let recordingURL = audioRecorder?.url
        audioRecorder = nil

        // Stop transcription
        stopLiveTranscription()

        let duration = recordingDuration
        let transcription = currentTranscription

        // Reset state
        recordingDuration = 0
        currentTranscription = ""

        return (recordingURL, transcription, duration)
    }

    /// Pause recording
    func pauseRecording() {
        guard isRecording else { return }
        audioRecorder?.pause()
        isPaused = true
        stopRecordingTimer()
    }

    /// Resume recording
    func resumeRecording() {
        guard isRecording, isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        startRecordingTimer()
    }

    // MARK: - Playback

    /// Play back recorded audio
    func playAudio(url: URL) async throws {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            throw RecordingError.playbackFailed
        }
    }

    /// Stop audio playback
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Private Setup Methods

    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func createRecordingURL() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let journalDirectory = documentsPath.appendingPathComponent("JournalRecordings", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: journalDirectory.path) {
            try FileManager.default.createDirectory(at: journalDirectory, withIntermediateDirectories: true)
        }

        let fileName = "journal_\(UUID().uuidString).m4a"
        return journalDirectory.appendingPathComponent(fileName)
    }

    private func setupAudioRecorder(url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }

    // MARK: - Timer Management

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Live Transcription

    private func startLiveTranscription() async throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Check speech recognizer availability
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw RecordingError.speechRecognitionUnavailable
        }

        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw RecordingError.speechRecognitionFailed
        }
        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on audio engine
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        isTranscribing = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.currentTranscription = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.stopLiveTranscription()
                }
            }
        }
    }

    private func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }

    // MARK: - Audio Level Monitoring

    /// Get current audio recording level (0.0 to 1.0)
    func getAudioLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        // Convert dB to 0-1 range
        let normalizedLevel = pow(10, averagePower / 20)
        return min(max(normalizedLevel, 0), 1)
    }

    // MARK: - Cleanup

    func cleanup() {
        // Stop recording directly without async
        isRecording = false
        stopRecordingTimer()
        audioRecorder?.stop()
        audioRecorder = nil
        stopLiveTranscription()
        recordingDuration = 0
        currentTranscription = ""
        // Stop playback
        stopPlayback()
    }

    deinit {
        // Direct cleanup without MainActor isolation
        audioRecorder?.stop()
        audioPlayer?.stop()
        recordingTimer?.invalidate()
    }
}

// MARK: - Recording Error

enum RecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case playbackFailed
    case speechRecognitionUnavailable
    case speechRecognitionFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied. Please enable microphone and speech recognition in Settings."
        case .recordingFailed:
            return "Failed to start recording. Please try again."
        case .playbackFailed:
            return "Failed to play audio. The file may be corrupted."
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available on this device."
        case .speechRecognitionFailed:
            return "Speech recognition failed. Please try again."
        }
    }
}
