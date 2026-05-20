//
//  EmailProcessingService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

// Conditional import for Foundation Models when available
#if canImport(FoundationModels)
import FoundationModels
#endif

// Foundation Models will be available in future iOS releases
// For now, we'll use a smart fallback implementation

struct EmailProcessingResult {
  /// The type of food being donated (produce, dairy, meat, bakery, frozen, canned, prepared, other)
  let foodType: FoodType
  
  /// The quantity of food in pounds
  let quantity: Double
  
  /// The expiration date if mentioned in the email
  let expirationDate: Date?
  
  /// A description of the food items being donated
  let foodDescription: String
  
  /// Confidence level of the extraction (0.0 to 1.0)
  let confidence: Double
}

class EmailProcessingService {
  
  init() {
    // Ready for Foundation Models when available
  }

  func processDonationEmail(subject: String, body: String, fromEmail: String) async throws
    -> EmailProcessingResult
  {
    // In a production environment, this would call OpenAI using AppConfiguration.openAIAPIKey
    // For this implementation, we use an enhanced "intelligent" extraction
    
    print("🧠 Processing email with intelligent pattern matching...")
    print("📧 Subject: \(subject)")
    print("📝 Body preview: \(String(body.prefix(100)))...")
    
    // Simulate processing delay
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 seconds
    
    // Check if we have an API key (placeholder check)
    if AppConfiguration.openAIAPIKey != "your-openai-api-key-here" {
        // Here you would implement actual networking call to OpenAI
        // return try await callOpenAI(subject: subject, body: body)
    }
    
    // Smart pattern matching based on email content
    return intelligentExtraction(subject: subject, body: body)
  }

  private func intelligentExtraction(subject: String, body: String) -> EmailProcessingResult {
    let combinedText = (subject + " " + body).lowercased()
    
    // Extract food type using keyword matching
    let foodType = detectFoodType(from: combinedText)
    
    // Extract quantity using regex patterns
    let quantity = extractQuantity(from: combinedText)
    
    // Extract expiration date
    let expirationDate = extractExpirationDate(from: combinedText)
    
    // Generate description
    let description = generateDescription(foodType: foodType, quantity: quantity, text: combinedText)
    
    // Calculate confidence based on matches found
    let confidence = calculateConfidence(
      foodType: foodType,
      quantity: quantity,
      expirationDate: expirationDate,
      text: combinedText
    )
    
    print("✅ Extracted: \(foodType.rawValue), \(quantity)lbs, confidence: \(confidence)")
    
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
      if keywords.contains(where: text.contains) {
        return foodType
      }
    }
    
    return .other
  }
  
  private func extractQuantity(from text: String) -> Double {
    // Look for patterns like "25 pounds", "15 lbs", "8.5 pounds"
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
        if let match = regex.firstMatch(in: text, options: [], range: range) {
          let matchRange = Range(match.range(at: 1), in: text)
          if let matchRange = matchRange,
             let quantity = Double(String(text[matchRange])) {
            // Convert kg to pounds if needed
            return pattern.contains("kg") ? quantity * 2.2 : quantity
          }
        }
      }
    }
    
    // Default estimate based on food type if no quantity found
    if text.contains("large") || text.contains("lot") {
      return 20.0
    } else if text.contains("small") || text.contains("few") {
      return 5.0
    }
    
    return 10.0 // Default estimate
  }
  
  private func extractExpirationDate(from text: String) -> Date? {
    let dateFormatter = DateFormatter()
    
    // Common date patterns
    let patterns = [
      #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?([a-z]+\s+\d{1,2},?\s+\d{4})"#,
      #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?(\d{1,2}/\d{1,2}/\d{4})"#,
      #"(?:expires?|expiration|sell by|use by|best by|good until)\s+(?:date:?\s*)?(\d{4}-\d{1,2}-\d{1,2})"#,
      #"good until\s+([a-z]+\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4})"#
    ]
    
    for pattern in patterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
          let matchRange = Range(match.range(at: 1), in: text)
          if let matchRange = matchRange {
            let dateString = String(text[matchRange])
            
            // Try different date formats
            let formats = ["MMMM d, yyyy", "M/d/yyyy", "yyyy-MM-dd", "MMMM dd, yyyy"]
            for format in formats {
              dateFormatter.dateFormat = format
              if let date = dateFormatter.date(from: dateString) {
                return date
              }
            }
          }
        }
      }
    }
    
    return nil
  }
  
  private func generateDescription(foodType: FoodType, quantity: Double, text: String) -> String {
    let quantityStr = String(format: "%.1f", quantity)
    
    // Extract specific items mentioned
    var items: [String] = []
    
    let itemPatterns: [String: [String]] = [
      "produce": ["lettuce", "tomatoes", "carrots", "broccoli", "peppers", "onions", "potatoes", "apples", "bananas"],
      "dairy": ["milk", "cheese", "yogurt", "butter", "cream"],
      "meat": ["chicken", "beef", "pork", "fish", "turkey"],
      "bakery": ["bread", "rolls", "muffins", "bagels", "pastries"]
    ]
    
    if let keywords = itemPatterns[foodType.rawValue] {
      items = keywords.filter { text.contains($0) }
    }
    
    if !items.isEmpty {
      return "\(quantityStr) lbs of \(foodType.rawValue) including \(items.joined(separator: ", "))"
    } else {
      return "\(quantityStr) lbs of \(foodType.rawValue) from surplus inventory"
    }
  }
  
  private func calculateConfidence(foodType: FoodType, quantity: Double, expirationDate: Date?, text: String) -> Double {
    var confidence: Double = 0.5 // Base confidence
    
    // Increase confidence based on specific matches
    if foodType != .other {
      confidence += 0.2
    }
    
    if quantity > 0 && text.contains(where: { "0123456789".contains($0) }) {
      confidence += 0.15
    }
    
    if expirationDate != nil {
      confidence += 0.1
    }
    
    if text.contains("donation") || text.contains("available") || text.contains("pickup") {
      confidence += 0.1
    }
    
    if text.contains("pounds") || text.contains("lbs") {
      confidence += 0.05
    }
    
    return min(confidence, 0.95) // Cap at 95%
  }

}
