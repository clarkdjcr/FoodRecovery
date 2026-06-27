// OperationNote.swift
// Lightweight operations log entry. Stores manual notes and system events
// (route completions, bulk SMS confirmations, etc.) for operator reference.

import Foundation
import SwiftData

enum NoteCategory: String, Codable {
    case note   = "note"
    case alert  = "alert"
    case sms    = "sms"
    case email  = "email"
    case route  = "route"
}

@Model
final class OperationNote {
    var id: UUID
    var content: String
    var authorName: String
    var category: String      // NoteCategory.rawValue
    var createdAt: Date

    init(content: String, authorName: String = "Operator", category: NoteCategory = .note) {
        self.id = UUID()
        self.content = content
        self.authorName = authorName
        self.category = category.rawValue
        self.createdAt = Date()
    }

    var noteCategory: NoteCategory { NoteCategory(rawValue: category) ?? .note }
}
