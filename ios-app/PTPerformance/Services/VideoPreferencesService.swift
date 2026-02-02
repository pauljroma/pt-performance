//
//  VideoPreferencesService.swift
//  PTPerformance
//
//  Created by Content & Polish Sprint Agent 3
//  Service for managing user video preferences
//

import Foundation
import Supabase

/// Service for managing user video preferences
/// Handles quality selection, autoplay settings, captions, and playback speed
@MainActor
class VideoPreferencesService: ObservableObject {

    // MARK: - Singleton

    static let shared = VideoPreferencesService()

    private init() {}

    // MARK: - Published Properties

    @Published var preferences: VideoPreferences?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let client = PTSupabaseClient.shared
    private let errorLogger = ErrorLogger.shared

    // MARK: - Models

    struct VideoPreferences: Codable, Identifiable {
        let id: UUID
        let patientId: UUID
        var preferredQuality: VideoQuality
        var autoPlay: Bool
        var showCaptions: Bool
        var playbackSpeed: Double

        enum CodingKeys: String, CodingKey {
            case id
            case patientId = "patient_id"
            case preferredQuality = "preferred_quality"
            case autoPlay = "auto_play"
            case showCaptions = "show_captions"
            case playbackSpeed = "playback_speed"
        }
    }

    // VideoQuality enum is defined in Models/VideoQuality.swift

    // MARK: - Fetch Preferences

    /// Fetch video preferences for the current user
    /// Creates default preferences if none exist
    /// - Throws: VideoPreferencesError if fetch fails
    func fetchPreferences() async throws {
        guard let patientId = client.userId else {
            throw VideoPreferencesError.noAuthenticatedUser
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Try to fetch existing preferences
            let response: [VideoPreferences] = try await client.client
                .from("user_video_preferences")
                .select()
                .eq("patient_id", value: patientId)
                .limit(1)
                .execute()
                .value

            if let existingPrefs = response.first {
                self.preferences = existingPrefs
            } else {
                // Create default preferences if none exist
                let defaultPrefs = try await createDefaultPreferences(patientId: patientId)
                self.preferences = defaultPrefs
            }
        } catch {
            self.error = error.localizedDescription
            errorLogger.logError(
                error,
                context: "VideoPreferencesService.fetchPreferences [patient_id: \(patientId)]"
            )
            throw VideoPreferencesError.fetchFailed(error)
        }
    }

    /// Create default preferences for a new user
    /// - Parameter patientId: The patient's UUID string
    /// - Returns: Newly created VideoPreferences
    private func createDefaultPreferences(patientId: String) async throws -> VideoPreferences {
        let defaultPrefs = VideoPreferencesInsert(
            patientId: patientId,
            preferredQuality: .auto,
            autoPlay: true,
            showCaptions: false,
            playbackSpeed: 1.0
        )

        let created: VideoPreferences = try await client.client
            .from("user_video_preferences")
            .insert(defaultPrefs)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    // MARK: - Update Preferences

    /// Update video preferences
    /// - Parameter preferences: The updated preferences to save
    /// - Throws: VideoPreferencesError if update fails
    func updatePreferences(_ preferences: VideoPreferences) async throws {
        guard client.userId != nil else {
            throw VideoPreferencesError.noAuthenticatedUser
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let update = VideoPreferencesUpdate(
                preferredQuality: preferences.preferredQuality,
                autoPlay: preferences.autoPlay,
                showCaptions: preferences.showCaptions,
                playbackSpeed: preferences.playbackSpeed
            )

            let updated: VideoPreferences = try await client.client
                .from("user_video_preferences")
                .update(update)
                .eq("id", value: preferences.id.uuidString)
                .select()
                .single()
                .execute()
                .value

            self.preferences = updated
        } catch {
            self.error = error.localizedDescription
            errorLogger.logError(
                error,
                context: "VideoPreferencesService.updatePreferences [preferences_id: \(preferences.id.uuidString)]"
            )
            throw VideoPreferencesError.updateFailed(error)
        }
    }

    // MARK: - Convenience Methods

    /// Set the preferred video quality
    /// - Parameter quality: The new quality setting
    /// - Throws: VideoPreferencesError if update fails
    func setPreferredQuality(_ quality: VideoQuality) async throws {
        guard var currentPrefs = preferences else {
            throw VideoPreferencesError.noPreferencesLoaded
        }

        currentPrefs.preferredQuality = quality
        try await updatePreferences(currentPrefs)
    }

    /// Toggle autoplay setting
    /// - Parameter enabled: Whether autoplay should be enabled
    /// - Throws: VideoPreferencesError if update fails
    func setAutoPlay(_ enabled: Bool) async throws {
        guard var currentPrefs = preferences else {
            throw VideoPreferencesError.noPreferencesLoaded
        }

        currentPrefs.autoPlay = enabled
        try await updatePreferences(currentPrefs)
    }

    /// Toggle captions setting
    /// - Parameter enabled: Whether captions should be shown
    /// - Throws: VideoPreferencesError if update fails
    func setShowCaptions(_ enabled: Bool) async throws {
        guard var currentPrefs = preferences else {
            throw VideoPreferencesError.noPreferencesLoaded
        }

        currentPrefs.showCaptions = enabled
        try await updatePreferences(currentPrefs)
    }

    /// Set playback speed
    /// - Parameter speed: Playback speed multiplier (0.5 to 2.0)
    /// - Throws: VideoPreferencesError if update fails or speed is out of range
    func setPlaybackSpeed(_ speed: Double) async throws {
        guard var currentPrefs = preferences else {
            throw VideoPreferencesError.noPreferencesLoaded
        }

        // Validate speed range
        guard speed >= 0.5 && speed <= 2.0 else {
            throw VideoPreferencesError.invalidPlaybackSpeed
        }

        currentPrefs.playbackSpeed = speed
        try await updatePreferences(currentPrefs)
    }

    /// Get the current preferred quality, defaulting to auto if not loaded
    var currentQuality: VideoQuality {
        preferences?.preferredQuality ?? .auto
    }

    /// Get the current playback speed, defaulting to 1.0 if not loaded
    var currentPlaybackSpeed: Double {
        preferences?.playbackSpeed ?? 1.0
    }

    /// Check if autoplay is enabled
    var isAutoPlayEnabled: Bool {
        preferences?.autoPlay ?? true
    }

    /// Check if captions are enabled
    var areCaptionsEnabled: Bool {
        preferences?.showCaptions ?? false
    }
}

// MARK: - Insert/Update Models

private struct VideoPreferencesInsert: Encodable {
    let patientId: String
    let preferredQuality: VideoQuality
    let autoPlay: Bool
    let showCaptions: Bool
    let playbackSpeed: Double

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case preferredQuality = "preferred_quality"
        case autoPlay = "auto_play"
        case showCaptions = "show_captions"
        case playbackSpeed = "playback_speed"
    }
}

private struct VideoPreferencesUpdate: Encodable {
    let preferredQuality: VideoQuality
    let autoPlay: Bool
    let showCaptions: Bool
    let playbackSpeed: Double

    enum CodingKeys: String, CodingKey {
        case preferredQuality = "preferred_quality"
        case autoPlay = "auto_play"
        case showCaptions = "show_captions"
        case playbackSpeed = "playback_speed"
    }
}

// MARK: - Errors

enum VideoPreferencesError: LocalizedError {
    case noAuthenticatedUser
    case noPreferencesLoaded
    case fetchFailed(Error)
    case updateFailed(Error)
    case invalidPlaybackSpeed

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user"
        case .noPreferencesLoaded:
            return "Video preferences not loaded"
        case .fetchFailed:
            return "Failed to load video preferences"
        case .updateFailed:
            return "Failed to save video preferences"
        case .invalidPlaybackSpeed:
            return "Playback speed must be between 0.5x and 2.0x"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noAuthenticatedUser:
            return "Please sign in to manage video preferences."
        case .noPreferencesLoaded:
            return "Try refreshing your preferences."
        case .fetchFailed:
            return "Please check your connection and try again."
        case .updateFailed:
            return "Your changes couldn't be saved. Please try again."
        case .invalidPlaybackSpeed:
            return "Choose a speed between 0.5x and 2.0x."
        }
    }
}
