//
//  TherapistLinkingViewModel.swift
//  PTPerformance
//

import SwiftUI
import Supabase

@MainActor
class TherapistLinkingViewModel: ObservableObject {
    @Published var linkingCode: String?
    @Published var codeExpiresAt: Date?
    @Published var isLinked: Bool = false
    @Published var therapistName: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    // MARK: - Computed Properties

    /// Time remaining until the linking code expires
    var timeRemaining: String? {
        guard let expiresAt = codeExpiresAt else { return nil }

        let now = Date()
        let interval = expiresAt.timeIntervalSince(now)

        guard interval > 0 else { return "Expired" }

        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Codable Response Types

    private struct PatientLink: Codable {
        let therapist_id: UUID?
    }

    private struct TherapistInfo: Codable {
        let first_name: String
        let last_name: String
    }

    private struct LinkCodeResponse: Codable {
        let code: String
        let expiresAt: String
    }

    // MARK: - Check Link Status

    func checkLinkStatus() async {
        isLoading = true
        errorMessage = nil

        guard let patientId = supabase.userId else {
            errorMessage = "We couldn't find your account. Please sign out and sign back in."
            isLoading = false
            return
        }

        do {
            let response: [PatientLink] = try await supabase.client
                .from("patients")
                .select("therapist_id")
                .eq("id", value: patientId)
                .execute()
                .value

            if let patient = response.first, let therapistId = patient.therapist_id {
                isLinked = true
                await fetchTherapistName(therapistId: therapistId.uuidString)
            } else {
                isLinked = false
                therapistName = nil
            }
        } catch {
            errorMessage = "We couldn't check your therapist connection. Please try again later."
        }

        isLoading = false
    }

    // MARK: - Fetch Therapist Name

    private func fetchTherapistName(therapistId: String) async {
        do {
            let response: [TherapistInfo] = try await supabase.client
                .from("therapists")
                .select("first_name, last_name")
                .eq("id", value: therapistId)
                .execute()
                .value

            if let therapist = response.first {
                therapistName = "\(therapist.first_name) \(therapist.last_name)"
            } else {
                therapistName = "Unknown Therapist"
            }
        } catch {
            therapistName = "Unknown Therapist"
        }
    }

    // MARK: - Generate Code

    func generateCode() async {
        isLoading = true
        errorMessage = nil

        guard let patientId = supabase.userId else {
            errorMessage = "We couldn't find your account. Please sign out and sign back in."
            isLoading = false
            return
        }

        do {
            let body: [String: String] = [
                "action": "generate",
                "patientId": patientId
            ]
            let bodyData = try JSONSerialization.data(withJSONObject: body)

            let responseData: Data = try await supabase.client.functions
                .invoke(
                    "link-therapist",
                    options: FunctionInvokeOptions(body: bodyData)
                ) { data, _ in data }

            let decoded = try JSONDecoder().decode(LinkCodeResponse.self, from: responseData)
            linkingCode = decoded.code

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            codeExpiresAt = formatter.date(from: decoded.expiresAt)
        } catch {
            errorMessage = "We couldn't create your linking code. Please check your connection and try again."
        }

        isLoading = false
    }

    // MARK: - Unlink Therapist

    func unlinkTherapist() async {
        isLoading = true
        errorMessage = nil

        guard let patientId = supabase.userId else {
            errorMessage = "We couldn't find your account. Please sign out and sign back in."
            isLoading = false
            return
        }

        do {
            let body: [String: String] = [
                "action": "unlink",
                "patientId": patientId
            ]

            _ = try await supabase.client.functions
                .invoke(
                    "link-therapist",
                    options: .init(body: body)
                )

            isLinked = false
            therapistName = nil
            linkingCode = nil
            codeExpiresAt = nil
        } catch {
            errorMessage = "We couldn't disconnect from your therapist. Please try again later."
        }

        isLoading = false
    }
}
