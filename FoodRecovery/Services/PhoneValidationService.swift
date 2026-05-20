//
//  PhoneValidationService.swift
//  FoodRecovery
//
//  Created by Claude Code on 9/12/25.
//

import Foundation

class PhoneValidationService {
    
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanedNumber = cleanPhoneNumber(phoneNumber)
        
        // Check if it's exactly 10 digits (US numbers without country code)
        // or 11 digits starting with 1 (US numbers with country code)
        if cleanedNumber.count == 10 {
            return cleanedNumber.allSatisfy { $0.isNumber }
        } else if cleanedNumber.count == 11 && cleanedNumber.first == "1" {
            return cleanedNumber.allSatisfy { $0.isNumber }
        }
        
        return false
    }
    
    static func cleanPhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleaned = cleanPhoneNumber(phoneNumber)
        
        if cleaned.count == 10 {
            let areaCode = String(cleaned.prefix(3))
            let firstThree = String(cleaned.dropFirst(3).prefix(3))
            let lastFour = String(cleaned.suffix(4))
            return "(\(areaCode)) \(firstThree)-\(lastFour)"
        } else if cleaned.count == 11 && cleaned.first == "1" {
            let withoutCountry = String(cleaned.dropFirst())
            let areaCode = String(withoutCountry.prefix(3))
            let firstThree = String(withoutCountry.dropFirst(3).prefix(3))
            let lastFour = String(withoutCountry.suffix(4))
            return "+1 (\(areaCode)) \(firstThree)-\(lastFour)"
        }
        
        return phoneNumber
    }
    
    static func getValidationError(for phoneNumber: String) -> String? {
        if phoneNumber.isEmpty {
            return "Phone number is required"
        }
        
        let cleaned = cleanPhoneNumber(phoneNumber)
        
        if cleaned.count < 10 {
            return "Phone number must be at least 10 digits"
        } else if cleaned.count > 11 {
            return "Phone number cannot be more than 11 digits"
        } else if cleaned.count == 11 && cleaned.first != "1" {
            return "11-digit numbers must start with 1 (US country code)"
        } else if !cleaned.allSatisfy({ $0.isNumber }) {
            return "Phone number must contain only numbers"
        }
        
        return nil
    }
}