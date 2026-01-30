//
//  CachedAsyncImage.swift
//  PTPerformance
//
//  Specialized cached image views for exercise thumbnails and profile images
//  Uses ImageCacheService for memory + disk caching
//

import SwiftUI

// MARK: - Exercise Thumbnail Image

/// Specialized cached image for exercise thumbnails with consistent styling
struct ExerciseThumbnailImage: View {
    let thumbnailUrl: String?
    let exerciseName: String
    var size: CGFloat = 60

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                exercisePlaceholder
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onAppear {
                        loadImageIfNeeded()
                    }
            }
        }
    }

    private var exercisePlaceholder: some View {
        ZStack {
            Color.blue.opacity(0.1)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.4))
                .foregroundColor(.blue.opacity(0.6))
        }
    }

    private func loadImageIfNeeded() {
        guard let urlString = thumbnailUrl,
              let url = URL(string: urlString),
              !isLoading,
              loadedImage == nil else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let image = try await ImageCacheService.shared.loadImage(from: url)
                self.loadedImage = image
            } catch {
                DebugLogger.shared.log("ExerciseThumbnailImage failed to load: \(error.localizedDescription)", level: .warning)
            }
            self.isLoading = false
        }
    }
}

// MARK: - Profile Avatar Image

/// Specialized cached image for user profile avatars with initials fallback
struct ProfileAvatarImage: View {
    let profileImageUrl: String?
    let firstName: String
    let lastName: String
    var size: CGFloat = 50

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                initialsPlaceholder
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .onAppear {
                        loadImageIfNeeded()
                    }
            }
        }
    }

    private var initialsPlaceholder: some View {
        ZStack {
            avatarColor
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var avatarColor: Color {
        // Consistent color based on name
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo, .teal]
        let hash = abs((firstName + lastName).hashValue)
        return colors[hash % colors.count]
    }

    private func loadImageIfNeeded() {
        guard let urlString = profileImageUrl,
              let url = URL(string: urlString),
              !isLoading,
              loadedImage == nil else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let image = try await ImageCacheService.shared.loadImage(from: url)
                self.loadedImage = image
            } catch {
                DebugLogger.shared.log("ProfileAvatarImage failed to load: \(error.localizedDescription)", level: .warning)
            }
            self.isLoading = false
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CachedAsyncImageComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Exercise thumbnail examples
            HStack(spacing: 16) {
                ExerciseThumbnailImage(
                    thumbnailUrl: nil,
                    exerciseName: "Back Squat"
                )

                ExerciseThumbnailImage(
                    thumbnailUrl: "https://example.com/squat.jpg",
                    exerciseName: "Back Squat",
                    size: 80
                )
            }

            Divider()

            // Profile avatar examples
            HStack(spacing: 16) {
                ProfileAvatarImage(
                    profileImageUrl: nil,
                    firstName: "John",
                    lastName: "Smith"
                )

                ProfileAvatarImage(
                    profileImageUrl: nil,
                    firstName: "Jane",
                    lastName: "Doe",
                    size: 60
                )

                ProfileAvatarImage(
                    profileImageUrl: "https://example.com/avatar.jpg",
                    firstName: "Test",
                    lastName: "User"
                )
            }
        }
        .padding()
    }
}
#endif
