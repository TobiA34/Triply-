//
//  TicketScannerManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import UIKit
import Vision

/// Extracted ticket information from scanned image
struct TicketInfo {
    var flightNumber: String?
    var trainNumber: String?
    var busNumber: String?
    var departureLocation: String?
    var arrivalLocation: String?
    var departureDate: Date?
    var departureTime: String?
    var arrivalDate: Date?
    var arrivalTime: String?
    var seatNumber: String?
    var bookingReference: String?
    var passengerName: String?
    var price: Double?
    var currency: String?
    var ticketType: String? // "flight", "train", "bus", "event"
    var airline: String?
    var rawText: String
}

@MainActor
class TicketScannerManager: ObservableObject {
    @Published var isProcessing = false
    @Published var extractedText: String = ""
    @Published var ticketInfo: TicketInfo?
    @Published var errorMessage: String?
    
    /// Process ticket image and extract information
    func scanTicket(image: UIImage) async {
        isProcessing = true
        extractedText = ""
        ticketInfo = nil
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            errorMessage = "Invalid image"
            return
        }
        
        // Use Vision framework for text recognition
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.isProcessing = false
                    self.errorMessage = "OCR Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                Task { @MainActor in
                    self.isProcessing = false
                    self.errorMessage = "No text found in image"
                }
                return
            }
            
            var fullText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                fullText += topCandidate.string + "\n"
            }
            
            Task { @MainActor in
                self.extractedText = fullText
                self.ticketInfo = self.parseTicketInfo(from: fullText)
                // Reduced delay for better performance - animation still visible but shorter
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds instead of 2
                self.isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            isProcessing = false
            errorMessage = "Failed to process image: \(error.localizedDescription)"
        }
    }
    
    /// Parse ticket information from extracted text
    private func parseTicketInfo(from text: String) -> TicketInfo {
        var info = TicketInfo(rawText: text)
        
        // Detect ticket type
        let lowerText = text.lowercased()
        if lowerText.contains("flight") || lowerText.contains("airline") || lowerText.contains("departure gate") {
            info.ticketType = "flight"
        } else if lowerText.contains("train") || lowerText.contains("railway") || lowerText.contains("rail") {
            info.ticketType = "train"
        } else if lowerText.contains("bus") || lowerText.contains("coach") {
            info.ticketType = "bus"
        } else if lowerText.contains("event") || lowerText.contains("concert") || lowerText.contains("show") {
            info.ticketType = "event"
        }
        
        // Extract flight number (e.g., "AA123", "DL456", "EK789")
        let flightPattern = "\\b([A-Z]{2,3}\\s*\\d{3,4})\\b"
        if let match = extractFirstMatch(pattern: flightPattern, in: text) {
            info.flightNumber = match.trimmingCharacters(in: .whitespaces)
            info.ticketType = info.ticketType ?? "flight"
        }
        
        // Extract train number (e.g., "TGV 1234", "ICE 5678")
        let trainPattern = "\\b([A-Z]{2,4}\\s*\\d{3,5})\\b"
        if info.flightNumber == nil, let match = extractFirstMatch(pattern: trainPattern, in: text) {
            info.trainNumber = match.trimmingCharacters(in: .whitespaces)
            info.ticketType = info.ticketType ?? "train"
        }
        
        // Extract bus number
        let busPattern = "\\b(BUS|COACH)\\s*([A-Z]?\\d{2,4})\\b"
        if let match = extractFirstMatch(pattern: busPattern, in: text, groupIndex: 2) {
            info.busNumber = match.trimmingCharacters(in: .whitespaces)
            info.ticketType = info.ticketType ?? "bus"
        }
        
        // Extract departure location (common patterns)
        let departurePatterns = [
            "from[:\\s]+([A-Z]{3})", // Airport codes
            "departure[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)",
            "dep[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)",
            "origin[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)"
        ]
        for pattern in departurePatterns {
            if let match = extractFirstMatch(pattern: pattern, in: text, caseSensitive: false) {
                info.departureLocation = match.trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Extract arrival location
        let arrivalPatterns = [
            "to[:\\s]+([A-Z]{3})", // Airport codes
            "arrival[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)",
            "arr[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)",
            "destination[:\\s]+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)"
        ]
        for pattern in arrivalPatterns {
            if let match = extractFirstMatch(pattern: pattern, in: text, caseSensitive: false) {
                info.arrivalLocation = match.trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Extract dates (various formats)
        let datePatterns = [
            "\\b(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})\\b",
            "\\b(\\d{1,2}\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\\s+\\d{2,4})\\b",
            "\\b((Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*\\s+\\d{1,2}\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)\\b"
        ]
        for pattern in datePatterns {
            if let match = extractFirstMatch(pattern: pattern, in: text, caseSensitive: false) {
                if let date = parseDate(from: match) {
                    if info.departureDate == nil {
                        info.departureDate = date
                    } else {
                        info.arrivalDate = date
                    }
                }
            }
        }
        
        // Extract times (HH:MM format)
        let timePattern = "\\b(\\d{1,2}:\\d{2})\\b"
        let times = extractAllMatches(pattern: timePattern, in: text)
        if !times.isEmpty {
            info.departureTime = times[0]
            if times.count > 1 {
                info.arrivalTime = times[1]
            }
        }
        
        // Extract seat number
        let seatPatterns = [
            "seat[:\\s]+([A-Z]?\\d{1,3}[A-Z]?)",
            "seat\\s+number[:\\s]+([A-Z]?\\d{1,3}[A-Z]?)",
            "\\b([A-Z]\\d{1,3}[A-Z]?)\\b" // Common seat format
        ]
        for pattern in seatPatterns {
            if let match = extractFirstMatch(pattern: pattern, in: text, caseSensitive: false) {
                info.seatNumber = match.trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Extract booking reference (6-8 alphanumeric characters)
        let bookingPattern = "\\b([A-Z0-9]{6,8})\\b"
        if let match = extractFirstMatch(pattern: bookingPattern, in: text) {
            // Filter out common false positives
            let falsePositives = ["DEPART", "ARRIVE", "RETURN", "TICKET", "PASSENGER"]
            if !falsePositives.contains(match) {
                info.bookingReference = match
            }
        }
        
        // Extract passenger name (look for "MR", "MRS", "MS" followed by name)
        let namePattern = "\\b(MR|MRS|MS|MISS|DR)\\.?\\s+([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)\\b"
        if let match = extractFirstMatch(pattern: namePattern, in: text, caseSensitive: false, groupIndex: 2) {
            info.passengerName = match.trimmingCharacters(in: .whitespaces)
        }
        
        // Extract price
        let pricePatterns = [
            "\\$\\s*([\\d,]+(?:\\.[\\d]{2})?)",
            "([\\d,]+(?:\\.[\\d]{2})?)\\s*\\$",
            "EUR\\s*([\\d,]+(?:\\.[\\d]{2})?)",
            "GBP\\s*([\\d,]+(?:\\.[\\d]{2})?)",
            "USD\\s*([\\d,]+(?:\\.[\\d]{2})?)",
            "total[:\\s]*([\\d,]+(?:\\.[\\d]{2})?)",
            "price[:\\s]*([\\d,]+(?:\\.[\\d]{2})?)"
        ]
        for pattern in pricePatterns {
            if let match = extractFirstMatch(pattern: pattern, in: text, caseSensitive: false) {
                let amountString = match.replacingOccurrences(of: ",", with: "")
                if let amount = Double(amountString) {
                    info.price = amount
                    // Detect currency
                    if pattern.contains("EUR") {
                        info.currency = "EUR"
                    } else if pattern.contains("GBP") {
                        info.currency = "GBP"
                    } else if pattern.contains("USD") || pattern.contains("\\$") {
                        info.currency = "USD"
                    }
                    break
                }
            }
        }
        
        // Extract airline name
        let airlines = ["American Airlines", "Delta", "United", "Lufthansa", "British Airways", "Air France", "Emirates", "Qatar", "Singapore Airlines", "Japan Airlines"]
        for airline in airlines {
            if lowerText.contains(airline.lowercased()) {
                info.airline = airline
                break
            }
        }
        
        return info
    }
    
    // MARK: - Helper Methods
    
    private func extractFirstMatch(pattern: String, in text: String, caseSensitive: Bool = true, groupIndex: Int = 1) -> String? {
        let options: NSRegularExpression.Options = caseSensitive ? [] : .caseInsensitive
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > groupIndex else {
            return nil
        }
        
        let matchRange = match.range(at: groupIndex)
        guard let swiftRange = Range(matchRange, in: text) else {
            return nil
        }
        
        return String(text[swiftRange])
    }
    
    private func extractAllMatches(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let swiftRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[swiftRange])
        }
    }
    
    private func parseDate(from string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "MM/dd/yyyy"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "dd/MM/yyyy"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "dd MMM yyyy"
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "EEE dd MMM yyyy"
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
}

