//
//  TemplateGrid.swift
//  PTPerformance
//
//  Reusable grid component for displaying workout templates with pagination support
//

import SwiftUI

// MARK: - Template Grid

struct TemplateGrid: View {
    let templates: [AnyWorkoutTemplate]
    let showFavoriteButton: Bool
    let isFavorite: (AnyWorkoutTemplate) -> Bool
    let onFavoriteToggle: (AnyWorkoutTemplate) -> Void
    let onTemplateSelect: (AnyWorkoutTemplate) -> Void
    let onRefresh: () async -> Void

    init(
        templates: [AnyWorkoutTemplate],
        showFavoriteButton: Bool = false,
        isFavorite: @escaping (AnyWorkoutTemplate) -> Bool,
        onFavoriteToggle: @escaping (AnyWorkoutTemplate) -> Void,
        onTemplateSelect: @escaping (AnyWorkoutTemplate) -> Void,
        onRefresh: @escaping () async -> Void
    ) {
        self.templates = templates
        self.showFavoriteButton = showFavoriteButton
        self.isFavorite = isFavorite
        self.onFavoriteToggle = onFavoriteToggle
        self.onTemplateSelect = onTemplateSelect
        self.onRefresh = onRefresh
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                ForEach(templates) { template in
                    TemplateCardView(
                        template: template,
                        isFavorite: isFavorite(template),
                        showFavoriteButton: showFavoriteButton,
                        onFavoriteToggle: { onFavoriteToggle(template) }
                    )
                    .onTapGesture {
                        onTemplateSelect(template)
                    }
                    .id(template.id)
                }
            }
            .padding()
        }
        .refreshable {
            await onRefresh()
        }
    }

    static let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
}

// MARK: - Paginated Template Grid

struct PaginatedTemplateGrid: View {
    let templates: [AnyWorkoutTemplate]
    let showFavoriteButton: Bool
    let hasMore: Bool
    let isLoadingMore: Bool
    let isFavorite: (AnyWorkoutTemplate) -> Bool
    let onFavoriteToggle: (AnyWorkoutTemplate) -> Void
    let onTemplateSelect: (AnyWorkoutTemplate) -> Void
    let onLoadMore: () -> Void
    let onRefresh: () async -> Void

    init(
        templates: [AnyWorkoutTemplate],
        showFavoriteButton: Bool = false,
        hasMore: Bool,
        isLoadingMore: Bool = false,
        isFavorite: @escaping (AnyWorkoutTemplate) -> Bool,
        onFavoriteToggle: @escaping (AnyWorkoutTemplate) -> Void,
        onTemplateSelect: @escaping (AnyWorkoutTemplate) -> Void,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () async -> Void
    ) {
        self.templates = templates
        self.showFavoriteButton = showFavoriteButton
        self.hasMore = hasMore
        self.isLoadingMore = isLoadingMore
        self.isFavorite = isFavorite
        self.onFavoriteToggle = onFavoriteToggle
        self.onTemplateSelect = onTemplateSelect
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: TemplateGrid.gridColumns, spacing: 12) {
                ForEach(templates) { template in
                    TemplateCardView(
                        template: template,
                        isFavorite: isFavorite(template),
                        showFavoriteButton: showFavoriteButton,
                        onFavoriteToggle: { onFavoriteToggle(template) }
                    )
                    .onTapGesture {
                        onTemplateSelect(template)
                    }
                    .id(template.id)
                }

                // Load more trigger
                if hasMore {
                    loadMoreSection
                }
            }
            .padding()
        }
        .refreshable {
            await onRefresh()
        }
    }

    @ViewBuilder
    private var loadMoreSection: some View {
        Color.clear
            .frame(height: 1)
            .onAppear {
                onLoadMore()
            }

        HStack {
            Spacer()
            if isLoadingMore {
                ProgressView()
                    .padding()
            } else {
                Button("Load More") {
                    onLoadMore()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding()
            }
            Spacer()
        }
    }
}
