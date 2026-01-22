//
//  FormValidation.swift
//  Itinero
//
//  Form validation utilities
//

import Foundation

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Form Validator
struct FormValidator {
    // Trip validation
    static func validateTripName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Trip name is required")
        }
        if trimmed.count < 3 {
            return .invalid("Trip name must be at least 3 characters")
        }
        if trimmed.count > 100 {
            return .invalid("Trip name must be less than 100 characters")
        }
        return .valid
    }
    
    static func validateTripDates(startDate: Date, endDate: Date) -> ValidationResult {
        if endDate < startDate {
            return .invalid("End date must be after start date")
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Start date shouldn't be more than 2 years in the past
        if let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: now),
           startDate < twoYearsAgo {
            return .invalid("Start date cannot be more than 2 years in the past")
        }
        
        // End date shouldn't be more than 10 years in the future
        if let tenYearsFromNow = calendar.date(byAdding: .year, value: 10, to: now),
           endDate > tenYearsFromNow {
            return .invalid("End date cannot be more than 10 years in the future")
        }
        
        // Trip duration shouldn't be more than 2 years
        if let duration = calendar.dateComponents([.day], from: startDate, to: endDate).day,
           duration > 730 {
            return .invalid("Trip duration cannot exceed 2 years")
        }
        
        return .valid
    }
    
    static func validateBudget(_ budget: String, isRequired: Bool = false) -> ValidationResult {
        let trimmed = budget.trimmingCharacters(in: .whitespaces)
        
        if isRequired && trimmed.isEmpty {
            return .invalid("Budget is required")
        }
        
        if !trimmed.isEmpty {
            guard let value = Double(trimmed) else {
                return .invalid("Budget must be a valid number")
            }
            if value < 0 {
                return .invalid("Budget cannot be negative")
            }
            if value > 10_000_000 {
                return .invalid("Budget amount is too large (max 10,000,000)")
            }
        }
        
        return .valid
    }
    
    static func validateTravelCompanions(_ count: Int) -> ValidationResult {
        if count < 1 {
            return .invalid("Must have at least 1 travel companion")
        }
        if count > 50 {
            return .invalid("Maximum 50 travel companions allowed")
        }
        return .valid
    }
    
    static func validateTag(_ tag: String) -> ValidationResult {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Tag cannot be empty")
        }
        if trimmed.count < 2 {
            return .invalid("Tag must be at least 2 characters")
        }
        if trimmed.count > 30 {
            return .invalid("Tag must be less than 30 characters")
        }
        return .valid
    }
    
    static func validateTags(_ tags: [String]) -> ValidationResult {
        if tags.count > 10 {
            return .invalid("Maximum 10 tags allowed")
        }
        for tag in tags {
            let result = validateTag(tag)
            if !result.isValid {
                return result
            }
        }
        return .valid
    }
    
    static func validateTripNotes(_ notes: String) -> ValidationResult {
        if notes.count > 2000 {
            return .invalid("Notes must be less than 2000 characters")
        }
        return .valid
    }
    
    static func validateDestinations(_ destinations: [Any]) -> ValidationResult {
        // Destinations are optional but recommended
        // No validation error, just a warning
        return .valid
    }
    
    // Destination validation
    static func validateDestinationName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Destination name is required")
        }
        if trimmed.count < 2 {
            return .invalid("Destination name must be at least 2 characters")
        }
        if trimmed.count > 100 {
            return .invalid("Destination name must be less than 100 characters")
        }
        return .valid
    }
    
    static func validateAddress(_ address: String) -> ValidationResult {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Address is required")
        }
        if trimmed.count < 5 {
            return .invalid("Address must be at least 5 characters")
        }
        return .valid
    }
    
    // Expense validation
    static func validateExpenseTitle(_ title: String) -> ValidationResult {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Expense title is required")
        }
        if trimmed.count < 2 {
            return .invalid("Expense title must be at least 2 characters")
        }
        return .valid
    }
    
    static func validateExpenseAmount(_ amount: String) -> ValidationResult {
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Amount is required")
        }
        guard let value = Double(trimmed), value > 0 else {
            return .invalid("Amount must be a positive number")
        }
        if value > 1_000_000 {
            return .invalid("Amount is too large")
        }
        return .valid
    }
    
    static func validateExpenseDate(_ date: Date) -> ValidationResult {
        let calendar = Calendar.current
        let now = Date()
        if date > calendar.date(byAdding: .day, value: 1, to: now) ?? now {
            return .invalid("Expense date cannot be in the future")
        }
        return .valid
    }
    
    // Itinerary validation
    static func validateItineraryTitle(_ title: String) -> ValidationResult {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Activity title is required")
        }
        if trimmed.count < 2 {
            return .invalid("Activity title must be at least 2 characters")
        }
        return .valid
    }
    
    static func validateLocation(_ location: String) -> ValidationResult {
        let trimmed = location.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .invalid("Location is required")
        }
        if trimmed.count < 2 {
            return .invalid("Location must be at least 2 characters")
        }
        if trimmed.count > 200 {
            return .invalid("Location must be less than 200 characters")
        }
        return .valid
    }
    
    // Notes validation (optional field)
    static func validateNotes(_ notes: String) -> ValidationResult {
        // Notes are optional, but if provided, check length
        if notes.count > 1000 {
            return .invalid("Notes must be less than 1000 characters")
        }
        return .valid
    }
}
