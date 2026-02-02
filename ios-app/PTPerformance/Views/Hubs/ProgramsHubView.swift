//
//  ProgramsHubView.swift
//  PTPerformance
//
//  BUILD 318: Tab Consolidation - Programs Hub
//  Combines Program Library and History into a single tab with segmented navigation
//
//  BUILD 320: Baseball Pack Integration
//  Added Baseball Pack promo card entry point in the programs section
//

import SwiftUI

/// Programs Hub View - Unified programs and history tab
/// Provides segmented access to Program Library and Workout History
struct ProgramsHubView: View {
    // MARK: - Environment

    @EnvironmentObject var storeKit: StoreKitService
    @ObservedObject private var supabase = PTSupabaseClient.shared

    // MARK: - State

    @State private var selectedSection: ProgramsSection = .programs

    // MARK: - Section Enum

    enum ProgramsSection: String, CaseIterable {
        case programs = "Programs"
        case baseball = "Baseball"
        case history = "History"

        var title: String { rawValue }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control for sub-sections
            segmentedPicker
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)

            // Content based on selection
            contentView
        }
    }

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(ProgramsSection.allCases, id: \.self) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Programs Section Picker")
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .programs:
            // Use the existing ProgramLibraryBrowserView which has its own NavigationStack
            ProgramLibraryBrowserView()
                .environmentObject(storeKit)

        case .baseball:
            // Baseball Pack section with premium gating
            NavigationStack {
                baseballContent
                    .navigationTitle("Baseball Pack")
                    .navigationBarTitleDisplayMode(.large)
            }

        case .history:
            // History needs NavigationStack wrapper since it doesn't have one
            NavigationStack {
                historyContent
                    .navigationTitle("History")
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }

    // MARK: - Baseball Content

    @ViewBuilder
    private var baseballContent: some View {
        if storeKit.hasBaseballAccess {
            // User owns the pack - show the browser
            BaseballPackBrowserView()
        } else {
            // User doesn't own the pack - show marketing/purchase view
            BaseballPackMarketingView()
                .environmentObject(storeKit)
        }
    }

    // MARK: - History Content

    @ViewBuilder
    private var historyContent: some View {
        if let patientId = supabase.userId {
            // Premium-gated history view
            if storeKit.isPremium {
                HistoryView(patientId: patientId)
            } else {
                PremiumLockedView(
                    feature: "History",
                    icon: "clock.arrow.circlepath",
                    description: "Track all your sessions and see your workout history"
                )
                .environmentObject(storeKit)
            }
        } else {
            // No patient ID available
            EmptyStateView(
                title: "Not Signed In",
                message: "Please sign in to view your workout history, programs, and track your progress.",
                icon: "person.crop.circle.badge.exclamationmark",
                iconColor: .orange
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ProgramsHubView()
        .environmentObject(StoreKitService.shared)
}
