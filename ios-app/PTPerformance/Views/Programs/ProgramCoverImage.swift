//
//  ProgramCoverImage.swift
//  PTPerformance
//
//  Reusable cover image component for programs with async loading support
//

import SwiftUI

struct ProgramCoverImage: View {
    let url: String?
    let size: CGSize
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let urlString = url, let imageUrl = URL(string: urlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "figure.run")
                .font(.system(size: min(size.width, size.height) * 0.4))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProgramCoverImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // With URL (will show placeholder during load)
            ProgramCoverImage(
                url: "https://example.com/image.jpg",
                size: CGSize(width: 150, height: 100)
            )

            // Without URL (shows placeholder)
            ProgramCoverImage(
                url: nil,
                size: CGSize(width: 150, height: 100)
            )

            // Larger size
            ProgramCoverImage(
                url: nil,
                size: CGSize(width: 300, height: 180),
                cornerRadius: 16
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}
#endif
