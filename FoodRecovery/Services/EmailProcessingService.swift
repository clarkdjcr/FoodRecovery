//
//  EmailProcessingService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

struct EmailProcessingResult {
    let foodType: FoodType
    let quantity: Double
    let expirationDate: Date?
    let foodDescription: String
    /// Confidence level of the extraction (0.0 to 1.0)
    let confidence: Double
}

enum EmailProcessingError: LocalizedError {
    case networkError(Error)
    case invalidResponse(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "AI processing returned HTTP \(code)."
        case .parseError:
            return "Could not parse AI processing response."
        }
    }
}

// MARK: -

class EmailProcessingService {

    func processDonationEmail(subject: String, body: String, fromEmail: String) async throws
        -> EmailProcessingResult
    {
        let provider = AppConfiguration.activeAIProvider
        let result = try await processWithFirebaseOrLocalFallback(
            subject: subject,
            body: body,
            fromEmail: fromEmail
        )

        FirebaseAnalyticsService.shared.log(
            .emailProcessed(aiProvider: provider.rawValue, confidence: result.confidence, success: true)
        )
        return result
    }

    // MARK: - Firebase AI with local fallback

    private func processWithFirebaseOrLocalFallback(
        subject: String,
        body: String,
        fromEmail: String
    ) async throws -> EmailProcessingResult {
        if let firebaseResult = try? await FirebaseAIService.shared.processDonationEmail(
            subject: subject,
            body: body,
            fromEmail: fromEmail
        ) {
            return firebaseResult
        }

        return intelligentExtraction(subject: subject, body: body)
    }

    // MARK: - Local pattern matching fallback

    private func intelligentExtraction(subject: String, body: String) -> EmailProcessingResult {
        let combinedText = (subject + " " + body).lowercased()

        let foodType = detectFoodType(from: combinedText)
        let quantity = extractQuantity(from: combinedText)
        let expirationDate = extractExpirationDate(from: combinedText)
        let description = generateDescription(foodType: foodType, quantity: quantity, text: combinedText)
        let confidence = calculateConfidence(
            foodType: foodType, quantity: quantity, expirationDate: expirationDate, text: combinedText)

        return EmailProcessingResult(
            foodType: foodType,
            quantity: quantity,
            expirationDate: expirationDate,
            foodDescription: description,
            confidence: confidence
        )
    }

    private func detectFoodType(from text: String) -> FoodType {
        let patterns: [(FoodType, [String])] = [
            (.produce, ["produce", "vegetables", "fruits", "lettuce", "tomatoes", "carrots", "broccoli", "peppers", "greens", "fresh"]),
            (.dairy, ["dairy", "milk", "cheese", "yogurt", "butter", "cream"]),
            (.meat, ["meat", "chicken", "beef", "pork", "fish", "seafood", "turkey", "protein"]),
            (.bakery, ["bread", "bakery", "pastries", "rolls", "baked goods", "muffins", "bagels"]),
            (.frozen, ["frozen", "ice cream", "frozen foods"]),
            (.canned, ["canned", "cans", "jarred", "preserved"]),
            (.prepared, ["prepared", "cooked", "meals", "ready to eat", "hot food"])
        ]
        for (foodType, keywords) in patterns {
            if keywords.contains(where: text.contains) { return foodType }
        }
        return .other
    }

    private func extractQuantity(from text: String) -> Double {
        let patterns = [
            #"(\d+\.?\d*)\s*(?:pounds?|lbs?|lb)"#,
            #"(\d+\.?\d*)\s*(?:kg|kilograms?)"#,
            #"approximately\s+(\d+\.?\d*)"#,
            #"about\s+(\d+\.?\d*)"#,
            #"(\d+\.?\d*)\s+(?:of|total)"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let matchRange = Range(match.range(at: 1), in: text),
                   let quantity = Double(String(text[matchRange])) {
                    return pattern.contains("kg") ? quantity * 2.2 : quantity
                }
            }
        }
        if text.contains("large") || text.contains("lot") { return 20.0 }
        if text.contains("small") || text.contains("few") { return 5.0 }
        return 10.0
    }

    private func extractExpirationDate(from text: String) -> Date? {
        let dateFormatter = DateFormatter()
        let patterns = [
            #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?([a-z]+\s+\d{1,2},?\s+\d{4})"#,
            #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?(\d{1,2}/\d{1,2}/\d{4})"#,
            #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?(\d{4}-\d{1,2}-\d{1,2})"#,
            #"good until\s+([a-z]+\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4})"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let matchRange = Range(match.range(at: 1), in: text) {
                    let dateString = String(text[matchRange])
                    for format in ["MMMM d, yyyy", "M/d/yyyy", "yyyy-MM-dd", "MMMM dd, yyyy"] {
                        dateFormatter.dateFormat = format
                        if let date = dateFormatter.date(from: dateString) { return date }
                    }
                }
            }
        }
        return nil
    }

    private func generateDescription(foodType: FoodType, quantity: Double, text: String) -> String {
        let quantityStr = String(format: "%.1f", quantity)
        let itemPatterns: [String: [String]] = [
            "produce": ["lettuce", "tomatoes", "carrots", "broccoli", "peppers", "onions", "potatoes", "apples", "bananas"],
            "dairy": ["milk", "cheese", "yogurt", "butter", "cream"],
            "meat": ["chicken", "beef", "pork", "fish", "turkey"],
            "bakery": ["bread", "rolls", "muffins", "bagels", "pastries"]
        ]
        if let keywords = itemPatterns[foodType.rawValue] {
            let found = keywords.filter { text.contains($0) }
            if !found.isEmpty {
                return "\(quantityStr) lbs of \(foodType.rawValue) including \(found.joined(separator: ", "))"
            }
        }
        return "\(quantityStr) lbs of \(foodType.rawValue) from surplus inventory"
    }

    private func calculateConfidence(foodType: FoodType, quantity: Double, expirationDate: Date?, text: String) -> Double {
        var confidence = 0.5
        if foodType != .other { confidence += 0.2 }
        if quantity > 0 && text.contains(where: { "0123456789".contains($0) }) { confidence += 0.15 }
        if expirationDate != nil { confidence += 0.1 }
        if text.contains("donation") || text.contains("available") || text.contains("pickup") { confidence += 0.1 }
        if text.contains("pounds") || text.contains("lbs") { confidence += 0.05 }
        return min(confidence, 0.95)
    }
}
