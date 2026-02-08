//
//  PTBriefButton.swift
//  PTPerformance
//
//  Reusable button component for navigating to PTBriefView
//  Provides consistent styling and accessibility for 60-second brief access
//

import SwiftUI

/// A reusable button component that navigates to PTBriefView
/// Supports both compact (icon only) and full (icon + text) display modes
struct PTBriefButton: View {
    let athleteId: UUID
    let athleteName: String
    var compact: Bool = false

    var body: some View {
        NavigationLink(destination: PTBriefView(athleteId: athleteId)) {
            if compact {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.modusTealAccent)
            } else {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("60s Brief")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.modusTealAccent)
                .cornerRadius(CornerRadius.md)
            }
        }
        .accessibilityLabel("View 60-second brief for \(athleteName)")
    }
}

// MARK: - Preview

#if DEBUG
struct PTBriefButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PTBriefButton(
                athleteId: UUID(),
                athleteName: "John Doe",
                compact: false
            )

            PTBriefButton(
                athleteId: UUID(),
                athleteName: "Jane Smith",
                compact: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
