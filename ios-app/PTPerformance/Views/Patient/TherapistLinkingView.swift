import SwiftUI
import UIKit

struct TherapistLinkingView: View {
    @StateObject private var viewModel = TherapistLinkingViewModel()
    @State private var showUnlinkConfirmation = false
    @State private var showCopiedToast = false

    // Timer for countdown updates
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.isLinked && viewModel.linkingCode == nil {
                // Show loading state while checking initial link status
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Checking therapist connection...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                therapistLinkingContent
            }
        }
        .navigationTitle("Therapist Linking")
        .task {
            await viewModel.checkLinkStatus()
        }
        .onReceive(timer) { _ in
            // Force UI update for countdown timer
            // The timeRemaining computed property will recalculate
            viewModel.objectWillChange.send()
        }
    }

    // MARK: - Therapist Linking Content

    private var therapistLinkingContent: some View {
        List {
            if viewModel.isLinked {
                // MARK: - Linked Therapist Section
                Section("Current Therapist") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(viewModel.therapistName ?? "Linked Therapist")
                            .font(.headline)
                    }

                    Button(role: .destructive) {
                        showUnlinkConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                            Text("Unlink Therapist")
                        }
                    }
                    .confirmationDialog(
                        "Unlink Therapist",
                        isPresented: $showUnlinkConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Unlink", role: .destructive) {
                            Task {
                                await viewModel.unlinkTherapist()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to unlink your therapist? They will no longer be able to view your progress or manage your programs.")
                    }
                }
            } else {
                // MARK: - Not Linked Section
                Section {
                    Text("Generate a linking code and share it with your physical therapist so they can connect to your account and manage your programs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        Task {
                            await viewModel.generateCode()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, Spacing.xxs)
                            }
                            Image(systemName: "key.fill")
                            Text("Generate Linking Code")
                        }
                    }
                    .disabled(viewModel.isLoading)

                    if let code = viewModel.linkingCode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Linking Code")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(code)
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.modusCyan)
                                .textSelection(.enabled)

                            if let timeRemaining = viewModel.timeRemaining {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text("Expires in \(timeRemaining)")
                                        .font(.caption2)
                                }
                                .foregroundColor(timeRemaining == "Expired" ? .red : .orange)
                            }
                        }
                        .padding(.vertical, Spacing.xxs)

                        HStack {
                            Button {
                                UIPasteboard.general.string = code
                                showCopiedToast = true

                                // Intentional delay: show "Copied!" feedback for 2 seconds
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    showCopiedToast = false
                                }
                            } label: {
                                Label(showCopiedToast ? "Copied!" : "Copy", systemImage: showCopiedToast ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: "My Modus linking code is: \(code)") {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("Link to a Therapist")
                }
            }

            // MARK: - Error Section
            if let errorMessage = viewModel.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
}
