import SwiftUI
import UIKit

struct TherapistLinkingView: View {
    @StateObject private var viewModel = TherapistLinkingViewModel()
    @State private var showUnlinkConfirmation = false

    var body: some View {
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
                                    .padding(.trailing, 4)
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
                                .foregroundColor(.blue)
                                .textSelection(.enabled)

                            if let expiresAt = viewModel.codeExpiresAt {
                                Text("Expires: \(expiresAt, style: .relative)")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)

                        HStack {
                            Button {
                                UIPasteboard.general.string = code
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: code) {
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
        .navigationTitle("Therapist Linking")
        .task {
            await viewModel.checkLinkStatus()
        }
    }
}
