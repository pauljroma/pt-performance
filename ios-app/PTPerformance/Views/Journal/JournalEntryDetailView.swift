import SwiftUI
import AVFoundation

// MARK: - Journal Entry Detail View

struct JournalEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var entry: JournalEntry
    @StateObject private var audioService = AudioRecordingService()
    @State private var isPlaying = false
    @State private var isEditing = false
    @State private var editedTranscription = ""
    @State private var showMoodPicker = false
    @State private var showTagPicker = false
    @FocusState private var isTextFieldFocused: Bool

    var onSave: (JournalEntry) -> Void
    var onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Date & Duration Header
                headerSection

                // Mood Selector
                moodSection

                // Tags Section
                tagsSection

                // Audio Playback
                if entry.audioURL != nil {
                    audioPlaybackSection
                }

                // Transcription
                transcriptionSection

                // Delete Button
                deleteButton
            }
            .padding(Spacing.lg)
        }
        .background(Color.modusSubtleGradient.ignoresSafeArea())
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Done") {
                        saveChanges()
                    }
                    .foregroundColor(.modusCyan)
                    .bold()
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                    .foregroundColor(.modusCyan)
                }
            }
        }
        .onAppear {
            editedTranscription = entry.transcription
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.modusTealAccent)
                Text(entry.formattedDate)
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.modusTealAccent)
                Text(entry.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Entry from \(entry.formattedDate), duration \(entry.formattedDuration)")
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("How did you feel?")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibleHeader()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(JournalEntry.Mood.allCases, id: \.self) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: entry.mood == mood,
                            isEnabled: isEditing
                        ) {
                            if isEditing {
                                entry.mood = mood
                                HapticFeedback.selectionChanged()
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.modusDeepTeal)
                .accessibleHeader()

            if isEditing {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(JournalEntry.Tag.allCases) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: entry.tags.contains(tag),
                                isEnabled: true
                            ) {
                                toggleTag(tag)
                            }
                        }
                    }
                }
            } else if !entry.tags.isEmpty {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(entry.tags, id: \.self) { tag in
                        TagChip(tag: tag, isSelected: true, isEnabled: false) {}
                    }
                }
            } else {
                Text("No tags")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Audio Playback Section

    private var audioPlaybackSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.modusTealAccent)
                Text("Audio Recording")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                Spacer()
            }

            Button(action: {
                togglePlayback()
            }) {
                HStack {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.modusCyan)

                    Text(isPlaying ? "Pause" : "Play Recording")
                        .font(.headline)
                        .foregroundColor(.modusCyan)

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.modusLightTeal.opacity(0.5))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(isPlaying ? "Pause recording" : "Play recording")
        }
        .padding(Spacing.md)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Transcription Section

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.modusTealAccent)
                Text("Transcription")
                    .font(.headline)
                    .foregroundColor(.modusDeepTeal)
                Spacer()
                if isEditing {
                    Image(systemName: "pencil")
                        .foregroundColor(.modusCyan)
                        .font(.caption)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isEditing ? "Transcription, editable" : "Transcription")

            if isEditing {
                TextEditor(text: $editedTranscription)
                    .frame(minHeight: 200)
                    .padding(Spacing.sm)
                    .background(Color(.systemBackground))
                    .cornerRadius(CornerRadius.sm)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel("Edit transcription")
            } else {
                Text(entry.transcription.isEmpty ? "No transcription available" : entry.transcription)
                    .font(.body)
                    .foregroundColor(entry.transcription.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.md)
        .background(Color.modusLightTeal)
        .cornerRadius(CornerRadius.md)
        .adaptiveShadow(Shadow.subtle)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(action: {
            HapticFeedback.warning()
            onDelete()
        }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Entry")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.red)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Delete this journal entry")
        .padding(.top, Spacing.lg)
    }

    // MARK: - Actions

    private func startEditing() {
        isEditing = true
        editedTranscription = entry.transcription
        HapticFeedback.light()
    }

    private func saveChanges() {
        entry.transcription = editedTranscription
        isEditing = false
        isTextFieldFocused = false
        onSave(entry)
        HapticFeedback.success()
    }

    private func toggleTag(_ tag: JournalEntry.Tag) {
        if entry.tags.contains(tag) {
            entry.tags.removeAll { $0 == tag }
        } else {
            entry.tags.append(tag)
        }
        HapticFeedback.selectionChanged()
    }

    private func togglePlayback() {
        guard let url = entry.audioURL else { return }

        if isPlaying {
            audioService.stopPlayback()
            isPlaying = false
            HapticFeedback.light()
        } else {
            Task {
                do {
                    try await audioService.playAudio(url: url)
                    isPlaying = true
                    HapticFeedback.medium()
                } catch {
                    print("Playback error: \(error)")
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: JournalEntry.Mood
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                Text(mood.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? mood.color : Color(.systemGray6))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel("\(mood.displayName) mood")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: JournalEntry.Tag
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tag.icon)
                    .font(.caption)
                Text(tag.displayName)
                    .font(.caption)
                    .bold()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? tag.color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isSelected ? tag.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel("\(tag.displayName) tag")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct JournalEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JournalEntryDetailView(
                entry: .constant(JournalEntry(
                    date: Date(),
                    transcription: "Today I felt great after my workout. Energy levels are high and I'm recovering well. Sleep was excellent last night.",
                    mood: .great,
                    tags: [.energy, .sleep, .training],
                    duration: 45
                )),
                onSave: { _ in },
                onDelete: {}
            )
        }
    }
}
#endif
