import SwiftUI

/// A compact readiness score badge with color indicator
struct ReadinessBadge: View {
    let score: Int
    let band: String
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large

        var scoreFont: Font {
            switch self {
            case .small: return .system(size: 16, weight: .bold, design: .rounded)
            case .medium: return .system(size: 24, weight: .bold, design: .rounded)
            case .large: return .system(size: 36, weight: .bold, design: .rounded)
            }
        }

        var circleSize: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 50
            case .large: return 70
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    init(score: Int, band: String, size: BadgeSize = .medium) {
        self.score = score
        self.band = band
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: size.strokeWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    WidgetColors.colorForBand(band),
                    style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Score text
            Text("\(score)")
                .font(size.scoreFont)
                .foregroundColor(WidgetColors.colorForBand(band))
        }
        .frame(width: size.circleSize, height: size.circleSize)
    }
}

/// A horizontal readiness indicator bar
struct ReadinessBar: View {
    let score: Int
    let band: String
    let showLabel: Bool

    init(score: Int, band: String, showLabel: Bool = true) {
        self.score = score
        self.band = band
        self.showLabel = showLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                HStack {
                    Text("Readiness")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(score)%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(WidgetColors.colorForBand(band))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(WidgetColors.colorForBand(band))
                        .frame(width: geometry.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ReadinessBadge(score: 85, band: "green", size: .large)
        ReadinessBadge(score: 65, band: "yellow", size: .medium)
        ReadinessBadge(score: 45, band: "orange", size: .small)

        ReadinessBar(score: 85, band: "green")
            .padding()
    }
    .padding()
}
