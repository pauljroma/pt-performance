//
//  VoiceLoggingService.swift
//  PTPerformanceWatch
//
//  Voice recognition service for hands-free set logging
//  ACP-824: Apple Watch Standalone App
//

import Foundation
import Speech
import AVFoundation

/// Voice logging service for processing voice commands on Apple Watch
/// Supports commands like "3 sets of 10 at 135" or "10 reps 135 pounds"
@MainActor
class VoiceLoggingService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isListening = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var resultsContinuation: AsyncStream<VoiceCommandResult>.Continuation?

    // MARK: - Public Streams

    var recognitionResults: AsyncStream<VoiceCommandResult> {
        AsyncStream { continuation in
            self.resultsContinuation = continuation
        }
    }

    // MARK: - Initialization

    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        checkAuthorization()
    }

    // MARK: - Authorization

    private func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }

    // MARK: - Listening Control

    func startListening() async throws {
        guard authorizationStatus == .authorized else {
            throw VoiceLoggingError.notAuthorized
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceLoggingError.speechRecognizerUnavailable
        }

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceLoggingError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Works offline

        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true

        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                // Create result with confidence
                let confidence = result.bestTranscription.segments.map { $0.confidence }.reduce(0, +) /
                    Double(max(1, result.bestTranscription.segments.count))

                let commandResult = VoiceCommandResult(
                    reps: nil,
                    weight: nil,
                    sets: nil,
                    rpe: nil,
                    rawText: transcription,
                    confidence: Double(confidence)
                )

                Task { @MainActor in
                    self.resultsContinuation?.yield(commandResult)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        resultsContinuation?.finish()
        resultsContinuation = nil
    }

    // MARK: - Voice Command Processing

    /// Processes raw voice text into structured workout data
    /// Supports various formats:
    /// - "10 reps" or "ten reps"
    /// - "135 pounds" or "135 lbs"
    /// - "3 sets of 10" or "3 x 10"
    /// - "10 reps at 135"
    /// - "RPE 8" or "effort 8"
    func processVoiceCommand(_ text: String) -> VoiceCommandResult? {
        let lowercased = text.lowercased()

        var reps: Int?
        var weight: Double?
        var sets: Int?
        var rpe: Int?

        // Extract reps
        reps = extractReps(from: lowercased)

        // Extract weight
        weight = extractWeight(from: lowercased)

        // Extract sets
        sets = extractSets(from: lowercased)

        // Extract RPE
        rpe = extractRPE(from: lowercased)

        // Calculate confidence based on what we found
        var matchCount = 0
        if reps != nil { matchCount += 1 }
        if weight != nil { matchCount += 1 }
        if sets != nil { matchCount += 1 }
        if rpe != nil { matchCount += 1 }

        let confidence = Double(matchCount) / 4.0

        return VoiceCommandResult(
            reps: reps,
            weight: weight,
            sets: sets,
            rpe: rpe,
            rawText: text,
            confidence: confidence
        )
    }

    // MARK: - Extraction Helpers

    private func extractReps(from text: String) -> Int? {
        // Patterns: "10 reps", "ten reps", "for 10"
        let patterns = [
            #"(\d+)\s*reps?"#,
            #"for\s*(\d+)"#,
            #"did\s*(\d+)"#,
            #"(\d+)\s*times"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression),
               let number = extractNumber(from: String(text[match])) {
                return number
            }
        }

        // Try word numbers
        return convertWordToNumber(in: text, forType: "reps")
    }

    private func extractWeight(from text: String) -> Double? {
        // Patterns: "135 pounds", "135 lbs", "at 135"
        let patterns = [
            #"(\d+\.?\d*)\s*(pounds?|lbs?|kilos?|kg)"#,
            #"at\s*(\d+\.?\d*)"#,
            #"with\s*(\d+\.?\d*)"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression),
               let number = extractDouble(from: String(text[match])) {
                return number
            }
        }

        return nil
    }

    private func extractSets(from text: String) -> Int? {
        // Patterns: "3 sets", "3 x 10", "3 sets of 10"
        let patterns = [
            #"(\d+)\s*sets?"#,
            #"(\d+)\s*x\s*\d+"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression),
               let number = extractNumber(from: String(text[match])) {
                return number
            }
        }

        return nil
    }

    private func extractRPE(from text: String) -> Int? {
        // Patterns: "RPE 8", "effort 8", "difficulty 8"
        let patterns = [
            #"rpe\s*(\d+)"#,
            #"effort\s*(\d+)"#,
            #"difficulty\s*(\d+)"#
        ]

        for pattern in patterns {
            if let match = text.range(of: pattern, options: .regularExpression),
               let number = extractNumber(from: String(text[match])) {
                return min(10, max(1, number))
            }
        }

        return nil
    }

    private func extractNumber(from text: String) -> Int? {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first
    }

    private func extractDouble(from text: String) -> Double? {
        let pattern = #"(\d+\.?\d*)"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return Double(text[range])
        }
        return nil
    }

    private func convertWordToNumber(in text: String, forType type: String) -> Int? {
        let wordNumbers: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "fifteen": 15, "twenty": 20
        ]

        for (word, number) in wordNumbers {
            if text.contains("\(word) \(type)") || text.contains("\(word) rep") {
                return number
            }
        }

        return nil
    }
}

// MARK: - Errors

enum VoiceLoggingError: Error, LocalizedError {
    case notAuthorized
    case speechRecognizerUnavailable
    case requestCreationFailed
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .speechRecognizerUnavailable:
            return "Speech recognizer is not available"
        case .requestCreationFailed:
            return "Could not create recognition request"
        case .audioSessionFailed:
            return "Could not configure audio session"
        }
    }
}
