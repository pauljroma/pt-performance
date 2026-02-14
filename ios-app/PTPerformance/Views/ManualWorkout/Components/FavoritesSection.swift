//
//  FavoritesSection.swift
//  PTPerformance
//
//  Component for displaying favorites and user-created workout templates
//

import SwiftUI

// MARK: - My Workouts Grid

struct MyWorkoutsGrid: View {
    let favoriteSystemTemplates: [SystemWorkoutTemplate]
    let favoritePatientTemplates: [PatientWorkoutTemplate]
    let userCreatedTemplates: [PatientWorkoutTemplate]
    let isFavoriteSystem: (UUID) -> Bool
    let isFavoritePatient: (UUID) -> Bool
    let onToggleFavoriteSystem: (UUID) -> Void
    let onToggleFavoritePatient: (UUID) -> Void
    let onSelectSystemTemplate: (SystemWorkoutTemplate) -> Void
    let onSelectPatientTemplate: (PatientWorkoutTemplate) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Favorites Section
                if !favoriteSystemTemplates.isEmpty || !favoritePatientTemplates.isEmpty {
                    favoritesSection
                }

                // User Created Section
                if !userCreatedTemplates.isEmpty {
                    userCreatedSection
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await onRefresh()
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Favorites")
                    .font(.headline)
                Spacer()
                Text("\(favoriteSystemTemplates.count + favoritePatientTemplates.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: TemplateGrid.gridColumns, spacing: 12) {
                // System favorites
                ForEach(favoriteSystemTemplates) { template in
                    let anyTemplate = AnyWorkoutTemplate(systemTemplate: template)
                    TemplateCardView(
                        template: anyTemplate,
                        isFavorite: true,
                        showFavoriteButton: true,
                        onFavoriteToggle: {
                            onToggleFavoriteSystem(template.id)
                        }
                    )
                    .onTapGesture {
                        onSelectSystemTemplate(template)
                    }
                    .id(template.id)
                }

                // Patient favorites
                ForEach(favoritePatientTemplates) { template in
                    let anyTemplate = AnyWorkoutTemplate(patientTemplate: template)
                    TemplateCardView(
                        template: anyTemplate,
                        isFavorite: true,
                        showFavoriteButton: true,
                        onFavoriteToggle: {
                            onToggleFavoritePatient(template.id)
                        }
                    )
                    .onTapGesture {
                        onSelectPatientTemplate(template)
                    }
                    .id(template.id)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - User Created Section

    private var userCreatedSection: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.modusCyan)
                Text("My Created Workouts")
                    .font(.headline)
                Spacer()
                Text("\(userCreatedTemplates.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: TemplateGrid.gridColumns, spacing: 12) {
                ForEach(userCreatedTemplates) { template in
                    let anyTemplate = AnyWorkoutTemplate(patientTemplate: template)
                    TemplateCardView(
                        template: anyTemplate,
                        isFavorite: isFavoritePatient(template.id),
                        showFavoriteButton: true,
                        onFavoriteToggle: {
                            onToggleFavoritePatient(template.id)
                        }
                    )
                    .onTapGesture {
                        onSelectPatientTemplate(template)
                    }
                    .id(template.id)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Template Section Header

struct TemplateSectionHeader: View {
    let title: String
    let icon: String
    let iconColor: Color
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}
