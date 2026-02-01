//
//  BaseballPackView.swift
//  PTPerformance
//
//  Main entry point for Baseball Pack - shows marketing/purchase if not owned,
//  content browser if owned.
//

import SwiftUI

struct BaseballPackView: View {
    @StateObject private var storeKit = StoreKitService.shared

    var body: some View {
        Group {
            if storeKit.hasBaseballAccess {
                BaseballPackBrowserView()
            } else {
                BaseballPackMarketingView()
            }
        }
        .navigationTitle("Baseball Pack")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BaseballPackView()
    }
}
