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
    case noAPIKey
    case networkError(Error)
    case invalidResponse(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Add it in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "OpenAI returned HTTP \(code). Check your API key."
        case .parseError:
            return "Could not parse OpenAI response."
        }
    }
}

// MARK: - OpenAI Codable types

private struct OpenAIRequest: Encodable {
    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages
        case responseFormat = "response_format"
    }
}

private struct OpenAIResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

private struct ExtractedDonation: Decodable {
    let foodType: String
    let quantity: Double
    let expirationDate: String?
    let foodDescription: String
    let confidence: Double
}

// MARK: -

class EmailProcessingService {

    func processDonationEmail(subject: String, body: String, fromEmail: String) async throws
        -> EmailProcessingResult
    {
        let provider = AppConfiguration.activeAIProvider
        let result: EmailProcessingResult

        switch provider {
        case .openAI:
            let key = AppConfiguration.openAIAPIKey
            if !key.isEmpty {
                result = try await callOpenAI(subject: subject, body: body, apiKey: key)
            } else {
                result = intelligentExtraction(subject: subject, body: body)
            }
        case .anthropic:
            let key = AppConfiguration.anthropicAPIKey
            if !key.isEmpty {
                result = try await callOpenAI(subject: subject, body: body, apiKey: key)
            } else {
                result = intelligentExtraction(subject: subject, body: body)
            }
        case .gemini:
            // Firebase AI (Gemini via Firebase backend) — no direct API key required
            if let firebaseResult = try? await FirebaseAIService.shared.processDonationEmail(
                subject: subject, body: body, fromEmail: fromEmail) {
                result = firebaseResult
            } else {
                let key = AppConfiguration.geminiAPIKey
                result = !key.isEmpty
                    ? try await callOpenAI(subject: subject, body: body, apiKey: key)
                    : intelligentExtraction(subject: subject, body: body)
            }
        }

        FirebaseAnalyticsService.shared.log(
            .emailProcessed(aiProvider: provider.rawValue, confidence: result.confidence, success: true)
        )
        return result
    }

    // MARK: - OpenAI

    private func callOpenAI(subject: String, body: String, apiKey: String) async throws
        -> EmailProcessingResult
    {
        let prompt = """
            Extract food donation details from this email and respond with a JSON object only — no markdown, no explanation.

            Required fields:
            - foodType: one of "produce", "dairy", "meat", "bakery", "frozen", "canned", "prepared", "other"
            - quantity: estimated weight in pounds as a number
            - expirationDate: ISO 8601 date string (YYYY-MM-DD) or null if not mentioned
            - foodDescription: a concise description of the donated items (one sentence)
            - confidence: your extraction confidence from 0.0 to 1.0

            Subject: \(subject)
            Body: \(body)
            """

        let requestBody = OpenAIRequest(
            model: AppConfiguration.openAIModel,
            messages: [OpenAIRequest.Message(role: "user", content: prompt)],
            responseFormat: OpenAIRequest.ResponseFormat(type: "json_object")
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw EmailProcessingError.parseError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw EmailProcessingError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw EmailProcessingError.invalidResponse(http.statusCode)
        }

        let openAIResponse: OpenAIResponse
        do {
            openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            throw EmailProcessingError.parseError
        }

        guard let contentData = openAIResponse.choices.first?.message.content.data(using: .utf8)
        else {
            throw EmailProcessingError.parseError
        }

        let extracted: ExtractedDonation
        do {
            extracted = try JSONDecoder().decode(ExtractedDonation.self, from: contentData)
        } catch {
            throw EmailProcessingError.parseError
        }

        var expirationDate: Date? = nil
        if let dateString = extracted.expirationDate {
            expirationDate = ISO8601DateFormatter().date(from: dateString)
            if expirationDate == nil {
                // Try YYYY-MM-DD without time component
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                expirationDate = formatter.date(from: dateString)
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
