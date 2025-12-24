//
//  WHOOPOnboardingView.swift
//  PTPerformance
//
//  Build 76 - WHOOP Integration
//

import SwiftUI

struct WHOOPOnboardingView: View {
    @StateObject private var whoopService = WHOOPService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .foregroundColor(.blue)

            // Title
            Text("Connect WHOOP")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Description
            Text("Automatically adjust your training based on your daily recovery score")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Features
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "heart.fill", text: "Track recovery score daily")
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Auto-adjust session volume")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Optimize training load")
            }
            .padding()

            Spacer()

            // Connect Button
            Button {
                whoopService.startOAuthFlow()
            } label: {
                Text("Connect WHOOP Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }

            // Maybe Later Button
            Button("Maybe Later") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

// Preview
struct WHOOPOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WHOOPOnboardingView()
    }
}
