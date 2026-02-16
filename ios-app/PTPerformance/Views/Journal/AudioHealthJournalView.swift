import SwiftUI

// MARK: - Audio Health Journal View

struct AudioHealthJournalView: View {
    @StateObject private var viewModel = AudioHealthJournalViewModel()
    @State private var showRecordingView = false
    @State private var searchText = ""
    @State private var selectedEntry: JournalEntry?
    @State private var showDeleteConfirmation = false
    @State private var entryToDelete: JournalEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.modusSubtleGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    if viewModel.filteredEntries.isEmpty {
                        emptyState
                    } else {
                        // Journal Entries List
                        entriesList
                    }
                }
            }
            .navigationTitle("Health Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showRecordingView = true
                        HapticFeedback.medium()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.modusCyan)
                    }
                    .accessibilityLabel("Record new journal entry")
                }
            }
            .sheet(isPresented: $showRecordingView) {
                JournalEntryRecordingView { entry in
                    viewModel.addEntry(entry)
                }
            }
            .navigationDestination(item: $selectedEntry) { entry in
                if let index = viewModel.entries.firstIndex(where: { $0.id == entry.id }) {
                    JournalEntryDetailView(
                        entry: $viewModel.entries[index],
                        onSave: { updated in
                            viewModel.updateEntry(updated)
                        },
                        onDelete: {
                            entryToDelete = entry
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        viewModel.deleteEntry(entry)
                        selectedEntry = nil
                        HapticFeedback.success()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadEntries()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search journal entries")

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(Spacing.sm)
            .background(Color(.systemGray6))
            .cornerRadius(CornerRadius.sm)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            title: searchText.isEmpty ? "No Journal Entries" : "No Results",
            message: searchText.isEmpty
                ? "Start recording your daily health check-ins to track your wellness journey"
                : "Try a different search term",
            icon: searchText.isEmpty ? "book.closed.fill" : "magnifyingglass",
            iconColor: .modusCyan,
            action: searchText.isEmpty ? EmptyStateView.EmptyStateAction(
                title: "Record First Entry",
                icon: "mic.fill",
                action: {
                    showRecordingView = true
                }
            ) : nil
        )
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredEntries) { entry in
                    JournalEntryCard(entry: entry) {
                        selectedEntry = entry
                        HapticFeedback.light()
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private static let fullDayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header: Date & Mood
                HStack {
                    // Mood emoji
                    Text(entry.mood.emoji)
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundColor(.modusDeepTeal)

                        Text(entry.mood.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(entry.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(entry.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Image(systemName: tag.icon)
                                        .font(.system(size: 10))
                                    Text(tag.displayName)
                                        .font(.system(size: 11))
                                }
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(tag.color.opacity(0.2))
                                .foregroundColor(tag.color)
                                .cornerRadius(CornerRadius.xs)
                            }
                        }
                    }
                }

                // Transcription preview
                if !entry.transcription.isEmpty {
                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("No transcription available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }

                // Audio indicator
                if entry.audioURL != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption)
                        Text("Audio available")
                            .font(.caption)
                    }
                    .foregroundColor(.modusTealAccent)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.modusLightTeal)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        colorScheme == .dark
                            ? Color.modusTealAccent.opacity(0.2)
                            : Color.clear,
                        lineWidth: 0.5
                    )
            )
            .adaptiveShadow(Shadow.medium)
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Journal entry from \(formattedDate), mood \(entry.mood.displayName)")
        .accessibilityHint("Tap to view details")
    }

    private var formattedDate: String {
        if Calendar.current.isDateInToday(entry.date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(entry.date) {
            return "Yesterday"
        } else if Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .weekOfYear) {
            return Self.fullDayNameFormatter.string(from: entry.date)
        } else {
            return Self.mediumDateFormatter.string(from: entry.date)
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: AnimationDuration.quick), value: configuration.isPressed)
    }
}

// MARK: - View Model

@MainActor
class AudioHealthJournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var searchQuery: String = ""

    private let storageKey = "healthJournalEntries"

    var filteredEntries: [JournalEntry] {
        if searchQuery.isEmpty {
            return entries.sorted { $0.date > $1.date }
        }

        let query = searchQuery.lowercased()
        return entries.filter { entry in
            entry.transcription.lowercased().contains(query) ||
            entry.tags.contains { $0.displayName.lowercased().contains(query) } ||
            entry.mood.displayName.lowercased().contains(query)
        }
        .sorted { $0.date > $1.date }
    }

    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = decoded
        }
    }

    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        saveEntries()
        HapticFeedback.success()
    }

    func updateEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }

        // Delete audio file if exists
        if let audioURL = entry.audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }

        saveEntries()
    }

    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AudioHealthJournalView_Previews: PreviewProvider {
    static var previews: some View {
        AudioHealthJournalView()
    }
}
#endif
