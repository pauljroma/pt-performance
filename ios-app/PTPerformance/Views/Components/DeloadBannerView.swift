import SwiftUI

/// Banner shown on home screen when a deload is recommended
/// Displays urgency level, title, subtitle, and navigation chevron
struct DeloadBannerView: View {
    // MARK: - Properties

    let urgency: DeloadUrgency
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Urgency icon
                ZStack {
                    Circle()
                        .fill(urgency.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: urgency.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(urgency.color)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(urgency.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(urgency.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .adaptiveShadow(Shadow.subtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(urgency.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(urgency.title). \(urgency.subtitle)")
        .accessibilityHint("Double tap to view recovery details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Dismissible Deload Banner

/// Dismissible banner for the Today view with View and dismiss actions
/// Color-coded by urgency level with special styling for required urgency
struct DismissibleDeloadBannerView: View {
    // MARK: - Properties

    let urgency: DeloadUrgency
    let onTap: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var isRequired: Bool {
        urgency == .required
    }

    private var backgroundColor: Color {
        isRequired ? urgency.color : urgency.color.opacity(0.1)
    }

    private var primaryTextColor: Color {
        isRequired ? .white : .primary
    }

    private var secondaryTextColor: Color {
        isRequired ? .white.opacity(0.8) : .secondary
    }

    private var iconColor: Color {
        isRequired ? .white : urgency.color
    }

    private var buttonColor: Color {
        isRequired ? .white : urgency.color
    }

    private var dismissButtonColor: Color {
        isRequired ? .white.opacity(0.6) : .secondary
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Urgency icon
            Image(systemName: urgency.icon)
                .font(.title2)
                .foregroundColor(iconColor)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(urgency.title)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)

                Text(urgency.subtitle)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }

            Spacer()

            // View button
            Button {
                onTap()
            } label: {
                Text("View")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(buttonColor)
            }
            .buttonStyle(PlainButtonStyle())

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(dismissButtonColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgency.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(urgency.title). \(urgency.subtitle)")
        .accessibilityHint("Tap View to see recovery details, or dismiss this notification")
    }
}

// MARK: - Compact Deload Banner

/// Compact version of the deload banner for use in toolbars or smaller spaces
struct CompactDeloadBanner: View {
    let urgency: DeloadUrgency
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: urgency.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(urgency.title)
                    .font(.subheadline.weight(.medium))

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(urgency.color)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(urgency.title)")
        .accessibilityHint("Double tap to view recovery details")
    }
}

// MARK: - Animated Deload Banner

/// Deload banner with attention-grabbing animation for high urgency
struct AnimatedDeloadBanner: View {
    let urgency: DeloadUrgency
    let onTap: () -> Void

    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    private var shouldAnimate: Bool {
        urgency == .required || urgency == .recommended
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Urgency icon with optional pulse animation
                ZStack {
                    if shouldAnimate {
                        Circle()
                            .fill(urgency.color.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0 : 1)
                    }

                    Circle()
                        .fill(urgency.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: urgency.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(urgency.color)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(urgency.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(urgency.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Action text with chevron
                HStack(spacing: 4) {
                    Text("View")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(urgency.color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: urgency.color.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(urgency.color.opacity(0.4), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if shouldAnimate {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(urgency.title). \(urgency.subtitle)")
        .accessibilityHint("Double tap to view recovery details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Deload Banner - Required") {
    VStack(spacing: 16) {
        DeloadBannerView(urgency: .required) {
            print("Tapped required")
        }

        DeloadBannerView(urgency: .recommended) {
            print("Tapped recommended")
        }

        DeloadBannerView(urgency: .suggested) {
            print("Tapped suggested")
        }
    }
    .padding()
}

#Preview("Compact Deload Banner") {
    VStack(spacing: 16) {
        CompactDeloadBanner(urgency: .required) {
            print("Tapped")
        }

        CompactDeloadBanner(urgency: .recommended) {
            print("Tapped")
        }

        CompactDeloadBanner(urgency: .suggested) {
            print("Tapped")
        }
    }
    .padding()
}

#Preview("Animated Deload Banner") {
    VStack(spacing: 16) {
        AnimatedDeloadBanner(urgency: .required) {
            print("Tapped required")
        }

        AnimatedDeloadBanner(urgency: .recommended) {
            print("Tapped recommended")
        }
    }
    .padding()
}

#Preview("Dismissible Deload Banner") {
    VStack(spacing: 16) {
        DismissibleDeloadBannerView(
            urgency: .required,
            onTap: { print("Tapped required") },
            onDismiss: { print("Dismissed required") }
        )

        DismissibleDeloadBannerView(
            urgency: .recommended,
            onTap: { print("Tapped recommended") },
            onDismiss: { print("Dismissed recommended") }
        )

        DismissibleDeloadBannerView(
            urgency: .suggested,
            onTap: { print("Tapped suggested") },
            onDismiss: { print("Dismissed suggested") }
        )
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        DeloadBannerView(urgency: .recommended) {
            print("Tapped")
        }

        AnimatedDeloadBanner(urgency: .required) {
            print("Tapped")
        }

        DismissibleDeloadBannerView(
            urgency: .required,
            onTap: { print("Tapped") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
