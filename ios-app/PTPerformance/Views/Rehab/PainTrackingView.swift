import SwiftUI

/// Pain Tracking View - Rehab mode tab for logging pain levels
/// Uses PainBodyDiagramView for interactive body-based pain mapping
struct PainTrackingView: View {
    @EnvironmentObject var storeKit: StoreKitService

    @State private var painLocations: [PainLocation] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Interactive pain body diagram
                    PainBodyDiagramView(painLocations: $painLocations)
                        .padding(.horizontal)

                    // Coming soon notice (visible when there are pain locations)
                    if !painLocations.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            Button {
                                // No-op: pain logging persistence not yet implemented
                            } label: {
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text("Pain Logging Coming Soon")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.secondary)
                                .cornerRadius(CornerRadius.md)
                            }
                            .disabled(true)
                            .padding(.horizontal)

                            Text("\(painLocations.count) location\(painLocations.count == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Instructions card when empty
                    if painLocations.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: "hand.tap")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text("How to Log Pain")
                                    .font(.headline)
                            }

                            Text("Tap any body region on the diagram above to log a pain location with intensity. You can add multiple locations and adjust intensity levels.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Pain log saving is not yet available. This feature is coming in a future update.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, Spacing.xs)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(CornerRadius.lg)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pain Tracking")
        }
    }
}
