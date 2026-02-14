import SwiftUI

// MARK: - Calculators Menu View (ACP-512 / ACP-514)

/// Top-level menu that links to the 1RM Calculator and Working Weight Calculator.
struct CalculatorsMenuView: View {

    var body: some View {
        List {
                NavigationLink {
                    OneRepMaxCalculatorView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundColor(.modusCyan)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("1RM Calculator")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Estimate your one-rep max")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityLabel("1RM Calculator")
                .accessibilityHint("Estimate your one-rep max from a submaximal lift")

                NavigationLink {
                    WorkingWeightCalculatorView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "scalemass")
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Working Weight Calculator")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Find your working weight for any goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityLabel("Working Weight Calculator")
                .accessibilityHint("Calculate working weights based on your training goal")
            }
        .navigationTitle("Calculators")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    CalculatorsMenuView()
}
