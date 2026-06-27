// OperationsFeedView.swift
// Chronological operations log. Operators can compose new notes inline.

import SwiftData
import SwiftUI

struct OperationsFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OperationNote.createdAt, order: .reverse)
    private var notes: [OperationNote]

    @State private var composing = false
    @State private var draftText = ""
    @State private var draftCategory: NoteCategory = .note

    var body: some View {
        VStack(spacing: 0) {
            if notes.isEmpty {
                emptyState
            } else {
                notesList
            }

            composerBar
        }
        .navigationTitle("Operations Feed")
    }

    // MARK: - Notes list

    private var notesList: some View {
        List {
            ForEach(notes) { note in
                FeedNoteRow(note: note)
            }
            .onDelete { indexSet in
                for i in indexSet { modelContext.delete(notes[i]) }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "No Activity Yet",
            systemImage: "text.bubble",
            description: Text("Post a note using the bar below to start your operations log.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Inline compose bar

    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                if composing {
                    CategoryPicker(selection: $draftCategory)
                }

                HStack(alignment: .bottom, spacing: 10) {
                    TextField(
                        "Add an operations note…",
                        text: $draftText,
                        axis: .vertical
                    )
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { composing = true } }

                    Button(action: submitNote) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(draftText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)

                    if composing {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                composing = false
                                draftText = ""
                                draftCategory = .note
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    // MARK: - Submit

    private func submitNote() {
        let text = draftText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let note = OperationNote(content: text, category: draftCategory)
        modelContext.insert(note)
        withAnimation(.easeInOut(duration: 0.2)) {
            draftText = ""
            composing = false
            draftCategory = .note
        }
    }
}

// MARK: - Category picker chips

private struct CategoryPicker: View {
    @Binding var selection: NoteCategory

    private let categories: [NoteCategory] = [.note, .alert, .sms, .email, .route]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selection = cat }) {
                        Label(cat.displayName, systemImage: cat.icon)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selection == cat ? cat.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .foregroundColor(selection == cat ? cat.accentColor : .secondary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Feed row

private struct FeedNoteRow: View {
    let note: OperationNote

    private var cat: NoteCategory { note.noteCategory }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Category icon column
            ZStack {
                Circle()
                    .fill(cat.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: cat.icon)
                    .font(.system(size: 14))
                    .foregroundColor(cat.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cat.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(cat.accentColor)
                    Spacer()
                    Text(note.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if note.authorName != "Operator" {
                    Text("— \(note.authorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - NoteCategory display helpers

private extension NoteCategory {
    var displayName: String {
        switch self {
        case .note:  return "Note"
        case .alert: return "Alert"
        case .sms:   return "SMS"
        case .email: return "Email"
        case .route: return "Route"
        }
    }

    var icon: String {
        switch self {
        case .note:  return "note.text"
        case .alert: return "exclamationmark.triangle.fill"
        case .sms:   return "message.fill"
        case .email: return "envelope.fill"
        case .route: return "map.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .note:  return .blue
        case .alert: return .red
        case .sms:   return .teal
        case .email: return .orange
        case .route: return .green
        }
    }
}
