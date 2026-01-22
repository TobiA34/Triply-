//
//  AIStructuredResponse.swift
//  Itinero
//
//  Created on 2024
//

import Foundation

// MARK: - Structured AI Response
struct AIStructuredResponse: Codable {
    let text: String  // Human-readable response
    let structuredData: StructuredData?
    
    struct StructuredData: Codable {
        let itineraryItems: [StructuredItineraryItem]?
        let suggestions: [StructuredSuggestion]?
        let documents: [StructuredDocument]?
        let actions: [StructuredAction]?
    }
}

// MARK: - Structured Itinerary Item
struct StructuredItineraryItem: Codable, Identifiable {
    let id: String
    let day: Int
    let date: String?  // ISO date string
    let title: String
    let details: String?
    let time: String?
    let location: String?
    let order: Int?
    let isBooked: Bool?
    let bookingReference: String?
}

// MARK: - Structured Suggestion
struct StructuredSuggestion: Codable, Identifiable {
    let id: String
    let type: String  // "location", "activity", "tip", "budget", "warning"
    let title: String
    let description: String
    let priority: String?  // "low", "medium", "high"
    let action: String?  // "add_to_itinerary", "add_expense", "add_destination", etc.
    let metadata: [String: String]?  // Additional data
}

// MARK: - Structured Document
struct StructuredDocument: Codable, Identifiable {
    let id: String
    let type: String  // "ticket", "receipt", "reservation", "passport", "other"
    let title: String
    let description: String?
    let fileName: String?
    let date: String?  // ISO date string
    let amount: Double?
    let relatedItemId: String?  // Link to itinerary item or expense
}

// MARK: - Structured Action
struct StructuredAction: Codable, Identifiable {
    let id: String
    let type: String  // "create_itinerary", "add_expense", "add_destination", "save_suggestion"
    let data: [String: String]?  // Action-specific data
    let label: String  // Human-readable action label
}

// MARK: - JSON Parser
class AIResponseParser {
    static func parseJSON(from text: String) -> AIStructuredResponse? {
        // Try to extract JSON from the response
        // Look for JSON blocks in markdown code fences or plain JSON
        
        // First, try to find JSON in code blocks
        if let jsonRange = text.range(of: "```json") ?? text.range(of: "```") {
            let startIndex = text.index(jsonRange.upperBound, offsetBy: 0)
            if let endRange = text.range(of: "```", range: startIndex..<text.endIndex) {
                let jsonString = String(text[startIndex..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return parseJSONString(jsonString)
            }
        }
        
        // Try to find JSON object directly
        if let jsonStart = text.range(of: "{") {
            let jsonString = String(text[jsonStart.lowerBound...])
            if let jsonEnd = jsonString.range(of: "}", options: .backwards) {
                let potentialJSON = String(jsonString[...jsonEnd.upperBound])
                return parseJSONString(potentialJSON)
            }
        }
        
        // If no JSON found, return text-only response
        return AIStructuredResponse(text: text, structuredData: nil)
    }
    
    private static func parseJSONString(_ jsonString: String) -> AIStructuredResponse? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(AIStructuredResponse.self, from: data)
            return response
        } catch {
            print("Failed to parse JSON: \(error)")
            return nil
        }
    }
    
    static func createStructuredResponse(
        text: String,
        itineraryItems: [StructuredItineraryItem]? = nil,
        suggestions: [StructuredSuggestion]? = nil,
        documents: [StructuredDocument]? = nil,
        actions: [StructuredAction]? = nil
    ) -> AIStructuredResponse {
        let structuredData = AIStructuredResponse.StructuredData(
            itineraryItems: itineraryItems,
            suggestions: suggestions,
            documents: documents,
            actions: actions
        )
        return AIStructuredResponse(text: text, structuredData: structuredData)
    }
}


