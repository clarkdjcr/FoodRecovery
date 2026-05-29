// FirebaseAIService.swift
// Wraps Firebase AI (Gemini) for donation email processing.
// Falls back gracefully if the Firebase AI SDK cannot complete the request.

import FirebaseAI
import Foundation

// MARK: - Firebase AI email processor

final class FirebaseAIService {
    static let shared = FirebaseAIService()

    private let model: GenerativeModel

    private init() {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        model = ai.generativeModel(modelName: "gemini-2.0-flash")
    }

    func processDonationEmail(
        subject: String,
        body: String,
        fromEmail: String
    ) async throws -> EmailProcessingResult {
        let prompt = """
            Extract food donation details from this email. Respond with a JSON object only — \
            no markdown, no explanation.

            Required fields:
            - foodType: one of "produce", "dairy", "meat", "bakery", "frozen", "canned", "prepared", "other"
            - quantity: estimated weight in pounds as a number
            - expirationDate: ISO 8601 date string (YYYY-MM-DD) or null if not mentioned
            - foodDescription: a concise one-sentence description of the donated items
            - confidence: your extraction confidence from 0.0 to 1.0

            From: \(fromEmail)
            Subject: \(subject)
            Body: \(body)
            """

        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw FirebaseAIError.emptyResponse
        }

        return try parseResponse(text)
    }

    // MARK: - Private parsing

    private struct ExtractedData: Decodable {
        let foodType: String
        let quantity: Double
        let expirationDate: String?
        let foodDescription: String
        let confidence: Double
    }

    private func parseResponse(_ text: String) throws -> EmailProcessingResult {
        // Strip any markdown code fences the model may include
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw FirebaseAIError.parseError
        }
        let extracted = try JSONDecoder().decode(ExtractedData.self, from: data)

        var expirationDate: Date?
        if let dateString = extracted.expirationDate {
            expirationDate = ISO8601DateFormatter().date(from: dateString)
            if expirationDate == nil {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                expirationDate = df.date(from: dateString)
            }
        }

        return EmailProcessingResult(
            foodType: FoodType(rawValue: extracted.foodType) ?? .other,
            quantity: max(extracted.quantity, 0),
            expirationDate: expirationDate,
            foodDescription: extracted.foodDescription,
            confidence: min(max(extracted.confidence, 0), 1)
        )
    }
}

// MARK: - Errors

enum FirebaseAIError: LocalizedError {
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Firebase AI returned an empty response."
        case .parseError: return "Could not parse the Firebase AI response."
        }
    }
}
