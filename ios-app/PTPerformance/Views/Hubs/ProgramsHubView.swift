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
        case packs = "Packs"
        case baseball = "Baseball"
        case history = "History"

        var title: String { rawValue }
    }

    // MARK: - Body

    var body: some View {
        // Single NavigationStack wrapping everything to prevent overlapping bars
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for sub-sections (inside NavigationStack)
                segmentedPicker
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                // Content based on selection (no more nested NavigationStacks)
                contentView
            }
            .navigationTitle(selectedSection.title)
            .navigationBarTitleDisplayMode(.large)
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
            // Programs browser (no nested NavigationStack - parent provides it)
            ProgramLibraryBrowserView()
                .environmentObject(storeKit)

        case .packs:
            // Premium Packs browser
            PremiumPacksBrowserView()
                .environmentObject(storeKit)

        case .baseball:
            // Baseball Pack section with premium gating
            baseballContent

        case .history:
            // History content
            historyContent
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
