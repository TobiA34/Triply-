//
//  AppleAIFoundation.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftUI
import NaturalLanguage
import CoreML
import Vision
import CoreImage

@MainActor
class AppleAIFoundation: ObservableObject {
    static let shared = AppleAIFoundation()
    
    @Published var isProcessing = false
    @Published var aiSuggestions: [AISuggestion] = []
    
    private let languageProcessor: NLLanguageRecognizer
    private let sentimentAnalyzer: NLModel?
    
    private init() {
        // Initialize Natural Language processor
        languageProcessor = NLLanguageRecognizer()
        
        // Initialize sentiment analyzer (using built-in sentiment analysis)
        sentimentAnalyzer = nil // We'll use NLTagger for sentiment
        
        // Load Core ML models if available
        loadMLModels()
    }
    
    // MARK: - Natural Language Processing
    
    func analyzeTripNotes(_ notes: String) -> TripAnalysis {
        var analysis = TripAnalysis()
        
        // Handle empty notes
        guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return analysis
        }
        
        // Detect language
        languageProcessor.processString(notes)
        if let dominantLanguage = languageProcessor.dominantLanguage {
            analysis.detectedLanguage = dominantLanguage.rawValue
        } else {
            analysis.detectedLanguage = "en" // Default to English
        }
        
        // Extract entities (places, dates, activities)
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = notes
        
        var locations: [String] = []
        var activities: [String] = []
        
        tagger.enumerateTags(in: notes.startIndex..<notes.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                switch tag {
                case .placeName:
                    let location = String(notes[tokenRange])
                    if !location.isEmpty && !locations.contains(location) {
                        locations.append(location)
                    }
                default:
                    break
                }
            }
            return true
        }
        
        // Extract keywords for activities
        tagger.enumerateTags(in: notes.startIndex..<notes.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, tag == .verb {
                let word = String(notes[tokenRange]).lowercased()
                if isActivityWord(word) && !activities.contains(word) {
                    activities.append(word)
                }
            }
            return true
        }
        
        analysis.extractedLocations = locations
        analysis.extractedActivities = activities
        analysis.sentiment = analyzeSentiment(notes)
        analysis.keywords = extractKeywords(from: notes)
        
        return analysis
    }
    
    func analyzeSentiment(_ text: String) -> Sentiment {
        guard !text.isEmpty else { return .neutral }
        
        // Use a simpler sentiment analysis approach
        let positiveWords = ["excited", "amazing", "wonderful", "great", "love", "enjoy", "fantastic", "beautiful", "perfect", "awesome", "happy", "fun"]
        let negativeWords = ["worried", "stress", "problem", "bad", "terrible", "awful", "disappointed", "sad", "difficult"]
        
        let lowerText = text.lowercased()
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords {
            if lowerText.contains(word) {
                positiveCount += 1
            }
        }
        
        for word in negativeWords {
            if lowerText.contains(word) {
                negativeCount += 1
            }
        }
        
        if positiveCount > negativeCount && positiveCount > 0 {
            return .positive
        } else if negativeCount > positiveCount && negativeCount > 0 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        let importantTags: Set<NLTag> = [.noun, .verb, .adjective]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, importantTags.contains(tag) {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 { // Filter short words
                    keywords.append(word)
                }
            }
            return true
        }
        
        // Return top keywords (remove duplicates, limit to 10)
        return Array(Set(keywords)).prefix(10).map { $0 }
    }
    
    // MARK: - Smart Trip Suggestions
    
    func generateSmartSuggestions(for trip: TripModel) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Small delay to show processing state
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        var suggestions: [AISuggestion] = []
        
        // Analyze trip notes
        let analysis = analyzeTripNotes(trip.notes)
        
        // Always add a welcome suggestion
        suggestions.append(AISuggestion(
            type: .tip,
            title: "Trip: \(trip.name)",
            description: "Your \(trip.duration)-day trip is planned. Here are some personalized recommendations to make it amazing!",
            priority: .high,
            action: nil
        ))
        
        // Generate suggestions based on analysis
        if !analysis.extractedLocations.isEmpty {
            suggestions.append(AISuggestion(
                type: .location,
                title: "Location Insights",
                description: "Found \(analysis.extractedLocations.count) location\(analysis.extractedLocations.count > 1 ? "s" : "") in your notes: \(analysis.extractedLocations.prefix(3).joined(separator: ", ")). Consider creating dedicated itinerary items for each.",
                priority: .high,
                action: "Add to Itinerary"
            ))
        } else if !trip.notes.isEmpty {
            suggestions.append(AISuggestion(
                type: .location,
                title: "Add Destinations",
                description: "Consider adding specific destinations to your trip notes for better planning and recommendations.",
                priority: .medium,
                action: nil
            ))
        }
        
        if analysis.sentiment == .positive {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Exciting Trip Ahead!",
                description: "Your notes show enthusiasm. Make sure to capture memories with photos during your trip.",
                priority: .medium,
                action: nil
            ))
        }
        
        // Budget analysis
        if let budget = trip.budget, budget > 0 {
            let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
            let remaining = budget - totalExpenses
            let percentage = budget > 0 ? (totalExpenses / budget) * 100 : 0
            
            if percentage > 80 {
                suggestions.append(AISuggestion(
                    type: .budget,
                    title: "Budget Alert",
                    description: "You've used \(Int(percentage))% of your budget. \(remaining > 0 ? "\(formatCurrency(remaining)) remaining." : "Consider reviewing expenses.")",
                    priority: .high,
                    action: "View Expenses"
                ))
            } else if percentage > 0 {
                suggestions.append(AISuggestion(
                    type: .budget,
                    title: "Budget Tracking",
                    description: "You've spent \(formatCurrency(totalExpenses)) of your \(formatCurrency(budget)) budget. \(formatCurrency(remaining)) remaining.",
                    priority: .medium,
                    action: "View Expenses"
                ))
            } else {
                suggestions.append(AISuggestion(
                    type: .budget,
                    title: "Budget Set",
                    description: "Your budget is \(formatCurrency(budget)). Start tracking expenses to stay on budget.",
                    priority: .medium,
                    action: "View Expenses"
                ))
            }
        } else {
            suggestions.append(AISuggestion(
                type: .budget,
                title: "Set a Budget",
                description: "Adding a budget helps you track expenses and stay on track financially.",
                priority: .low,
                action: nil
            ))
        }
        
        // Duration-based suggestions
        let days = trip.duration
        if days > 14 {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Extended Trip Tips",
                description: "For a \(days)-day trip, consider packing versatile clothing, planning rest days, and booking accommodations in advance.",
                priority: .medium,
                action: nil
            ))
        } else if days > 7 {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Week-Long Trip",
                description: "For a \(days)-day trip, pack versatile clothing and plan a mix of activities and relaxation time.",
                priority: .medium,
                action: nil
            ))
        } else if days > 3 {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Short Getaway",
                description: "For a \(days)-day trip, focus on 2-3 key experiences. Book popular spots in advance.",
                priority: .medium,
                action: nil
            ))
        }
        
        // Category-based suggestions
        switch trip.category.lowercased() {
        case "business":
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Business Trip Tips",
                description: "Keep receipts organized for expense reports. Consider time zone differences for meetings. Pack professional attire.",
                priority: .medium,
                action: nil
            ))
        case "vacation", "leisure":
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Vacation Mode",
                description: "Relax and enjoy! Don't over-schedule. Leave time for spontaneous discoveries and local experiences.",
                priority: .low,
                action: nil
            ))
        case "adventure":
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Adventure Ready",
                description: "Check weather conditions and pack appropriate gear. Share your itinerary with someone back home for safety.",
                priority: .high,
                action: nil
            ))
        default:
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Trip Planning",
                description: "Make the most of your trip by planning activities, tracking expenses, and capturing memories.",
                priority: .low,
                action: nil
            ))
        }
        
        // Add suggestions based on upcoming/past status
        if trip.isUpcoming {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Upcoming Trip",
                description: "Your trip starts \(formatDaysUntil(trip.startDate)). Make sure your packing list is ready and accommodations are confirmed.",
                priority: .medium,
                action: nil
            ))
        } else if trip.isCurrent {
            suggestions.append(AISuggestion(
                type: .tip,
                title: "Currently Traveling",
                description: "You're on your trip now! Track expenses in real-time and capture photos for memories.",
                priority: .high,
                action: nil
            ))
        }
        
        self.aiSuggestions = suggestions
    }
    
    private func formatDaysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "tomorrow"
        } else {
            return "in \(days) days"
        }
    }
    
    // MARK: - Image Analysis (Vision Framework)
    
    func analyzeReceiptImage(_ imageData: Data) async -> ReceiptAnalysis? {
        guard let uiImage = UIImage(data: imageData) else { return nil }
        
        return await withCheckedContinuation { continuation in
            guard let cgImage = uiImage.cgImage else {
                continuation.resume(returning: nil)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var extractedText = ""
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    extractedText += topCandidate.string + "\n"
                }
                
                let analysis = self.parseReceiptText(extractedText)
                continuation.resume(returning: analysis)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func parseReceiptText(_ text: String) -> ReceiptAnalysis {
        var analysis = ReceiptAnalysis()
        
        // Extract amount (look for currency patterns)
        let amountPattern = #"\$?\s*(\d+\.?\d{2})"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let amountRange = Range(match.range(at: 1), in: text) {
            analysis.amount = Double(text[amountRange])
        }
        
        // Extract date
        let datePattern = #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#
        if let regex = try? NSRegularExpression(pattern: datePattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let dateRange = Range(match.range, in: text) {
            let dateString = String(text[dateRange])
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            analysis.date = formatter.date(from: dateString)
        }
        
        // Extract merchant name (usually first line)
        let lines = text.components(separatedBy: .newlines)
        if !lines.isEmpty {
            analysis.merchant = lines.first?.trimmingCharacters(in: .whitespaces)
        }
        
        return analysis
    }
    
    // MARK: - Helper Methods
    
    private func isActivityWord(_ word: String) -> Bool {
        let activityWords = ["visit", "explore", "see", "go", "travel", "tour", "hike", "swim", "dive", "climb", "sightsee", "discover"]
        return activityWords.contains(word)
    }
    
    // MARK: - Advanced ChatGPT-like Conversational AI
    
    func generateChatResponse(
        userMessage: String,
        for trip: TripModel,
        conversationHistory: [ChatMessage] = []
    ) async -> String {
        let structured = await generateStructuredChatResponse(
            userMessage: userMessage,
            for: trip,
            conversationHistory: conversationHistory
        )
        return structured.text
    }
    
    func generateStructuredChatResponse(
        userMessage: String,
        for trip: TripModel,
        conversationHistory: [ChatMessage] = []
    ) async -> AIStructuredResponse {
        // Simulate thinking time for more natural conversation
        try? await Task.sleep(nanoseconds: 800_000_000 + UInt64.random(in: 0...600_000_000)) // 0.8-1.4 seconds
        
        let lowerMessage = userMessage.lowercased()
        
        // Deep conversation analysis
        let context = analyzeConversationContext(message: lowerMessage, history: conversationHistory)
        
        // Multi-layered intent detection
        let intent = detectIntent(from: lowerMessage, context: context)
        
        // Build comprehensive understanding
        let understanding = buildComprehensiveUnderstanding(
            message: userMessage,
            lowerMessage: lowerMessage,
            trip: trip,
            context: context,
            history: conversationHistory
        )
        
        // Generate sophisticated, contextual response with structured data
        return generateStructuredResponse(
            intent: intent,
            understanding: understanding,
            trip: trip,
            context: context,
            originalMessage: userMessage
        )
    }
    
    private struct ComprehensiveUnderstanding {
        var primaryIntent: ChatIntent
        var secondaryIntents: [ChatIntent] = []
        var extractedInfo: AdvancedTextAnalysis
        var conversationSummary: String = ""
        var userPersonality: UserPersonality = .neutral
        var urgency: UrgencyLevel = .normal
        var responseStyle: ResponseStyle = .helpful
        var keyInsights: [String] = []
    }
    
    private enum UserPersonality {
        case detailed, casual, direct, exploratory, neutral
    }
    
    private enum UrgencyLevel {
        case urgent, normal, relaxed
    }
    
    private enum ResponseStyle {
        case helpful, encouraging, analytical, friendly, professional
    }
    
    private func buildComprehensiveUnderstanding(
        message: String,
        lowerMessage: String,
        trip: TripModel,
        context: ConversationContext,
        history: [ChatMessage]
    ) -> ComprehensiveUnderstanding {
        var understanding = ComprehensiveUnderstanding(
            primaryIntent: .general,
            extractedInfo: performAdvancedTextAnalysis(message)
        )
        
        // Detect primary and secondary intents
        understanding.primaryIntent = detectIntent(from: lowerMessage, context: context)
        understanding.secondaryIntents = detectSecondaryIntents(from: lowerMessage)
        
        // Analyze user personality from conversation
        understanding.userPersonality = detectUserPersonality(from: message, history: history)
        
        // Detect urgency
        understanding.urgency = detectUrgency(from: lowerMessage)
        
        // Determine response style
        understanding.responseStyle = determineResponseStyle(
            personality: understanding.userPersonality,
            sentiment: understanding.extractedInfo.sentiment,
            urgency: understanding.urgency
        )
        
        // Build conversation summary
        understanding.conversationSummary = buildConversationSummary(history: history, currentMessage: message)
        
        // Extract key insights
        understanding.keyInsights = extractKeyInsights(
            trip: trip,
            analysis: understanding.extractedInfo,
            context: context
        )
        
        return understanding
    }
    
    private func detectSecondaryIntents(from message: String) -> [ChatIntent] {
        var intents: [ChatIntent] = []
        let lower = message.lowercased()
        
        // Check for multiple intents in one message
        if lower.contains("budget") || lower.contains("cost") || lower.contains("money") {
            intents.append(.budget)
        }
        if lower.contains("suggest") || lower.contains("recommend") || lower.contains("idea") {
            intents.append(.suggestions)
        }
        if lower.contains("itinerary") || lower.contains("schedule") || lower.contains("plan") {
            intents.append(.itinerary)
        }
        if lower.contains("expense") || lower.contains("spent") {
            intents.append(.expenses)
        }
        
        return intents
    }
    
    private func detectUserPersonality(from message: String, history: [ChatMessage]) -> UserPersonality {
        let messageLength = message.count
        let wordCount = message.components(separatedBy: .whitespaces).count
        
        // Analyze message patterns
        if messageLength > 100 || wordCount > 15 {
            return .detailed
        } else if messageLength < 30 || wordCount < 5 {
            return .direct
        } else if message.contains("?") && message.contains("how") || message.contains("why") {
            return .exploratory
        } else if message.contains("!") || message.contains("love") || message.contains("excited") {
            return .casual
        }
        
        return .neutral
    }
    
    private func detectUrgency(from message: String) -> UrgencyLevel {
        let urgentKeywords = ["urgent", "asap", "immediately", "now", "quick", "fast", "emergency", "help", "problem", "issue"]
        let relaxedKeywords = ["eventually", "later", "someday", "maybe", "thinking about", "considering"]
        
        let lower = message.lowercased()
        if urgentKeywords.contains(where: lower.contains) {
            return .urgent
        } else if relaxedKeywords.contains(where: lower.contains) {
            return .relaxed
        }
        return .normal
    }
    
    private func determineResponseStyle(
        personality: UserPersonality,
        sentiment: Sentiment,
        urgency: UrgencyLevel
    ) -> ResponseStyle {
        if urgency == .urgent {
            return .professional
        }
        if sentiment == .positive {
            return .encouraging
        }
        if personality == .exploratory {
            return .analytical
        }
        if personality == .casual {
            return .friendly
        }
        return .helpful
    }
    
    private func buildConversationSummary(history: [ChatMessage], currentMessage: String) -> String {
        let recentMessages = history.suffix(4)
        var topics: [String] = []
        
        for msg in recentMessages {
            if msg.isUser {
                let analysis = performAdvancedTextAnalysis(msg.text)
                topics.append(contentsOf: analysis.keyTopics.prefix(3))
            }
        }
        
        return topics.joined(separator: ", ")
    }
    
    private func extractKeyInsights(
        trip: TripModel,
        analysis: AdvancedTextAnalysis,
        context: ConversationContext
    ) -> [String] {
        var insights: [String] = []
        
        if !analysis.locations.isEmpty {
            insights.append("User mentioned locations: \(analysis.locations.joined(separator: ", "))")
        }
        if let firstAmount = analysis.amounts.first {
            insights.append("User mentioned budget: \(formatCurrency(firstAmount))")
        }
        if !analysis.preferences.isEmpty {
            insights.append("User preferences: \(analysis.preferences.joined(separator: ", "))")
        }
        if trip.budget != nil {
            insights.append("Trip has budget set")
        }
        if (trip.expenses?.count ?? 0) > 0 {
            insights.append("User has logged expenses")
        }
        
        return insights
    }
    
    private struct ConversationContext {
        var previousTopics: [String] = []
        var mentionedLocations: [String] = []
        var mentionedAmounts: [Double] = []
        var conversationFlow: [String] = []
        var userPreferences: [String] = []
        var followUpQuestion: Bool = false
    }
    
    private func analyzeConversationContext(message: String, history: [ChatMessage]) -> ConversationContext {
        var context = ConversationContext()
        
        // Analyze last few messages for context
        let recentHistory = history.suffix(6) // Last 6 messages
        
        for msg in recentHistory {
            if !msg.isUser {
                // Extract topics from AI responses using advanced NLP
                let analysis = analyzeTripNotes(msg.text)
                context.previousTopics.append(contentsOf: analysis.keywords)
                context.mentionedLocations.append(contentsOf: analysis.extractedLocations)
            } else {
                // Extract user preferences and mentions using ML-powered analysis
                let userAnalysis = performAdvancedTextAnalysis(msg.text)
                context.mentionedLocations.append(contentsOf: userAnalysis.locations)
                context.userPreferences.append(contentsOf: userAnalysis.preferences)
                context.mentionedAmounts.append(contentsOf: userAnalysis.amounts)
                context.previousTopics.append(contentsOf: userAnalysis.keyTopics)
            }
        }
        
        // Advanced follow-up detection using NLP
        context.followUpQuestion = detectFollowUpQuestion(message: message, history: recentHistory)
        
        return context
    }
    
    // MARK: - Advanced ML-Powered Text Analysis
    
    private struct AdvancedTextAnalysis {
        var locations: [String] = []
        var preferences: [String] = []
        var amounts: [Double] = []
        var keyTopics: [String] = []
        var entities: [String] = []
        var sentiment: Sentiment = .neutral
        var questionType: String? = nil
    }
    
    private func performAdvancedTextAnalysis(_ text: String) -> AdvancedTextAnalysis {
        var analysis = AdvancedTextAnalysis()
        
        // Use NLTagger with multiple schemes for comprehensive analysis
        let tagger = NLTagger(tagSchemes: [
            .nameType,           // Named entities (people, places, organizations)
            .lexicalClass,        // Parts of speech
            .sentimentScore,      // Sentiment analysis
            .tokenType            // Token types
        ])
        tagger.string = text
        
        // Extract named entities (locations, organizations, etc.)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                switch tag {
                case .placeName:
                    let location = String(text[tokenRange])
                    if !location.isEmpty && !analysis.locations.contains(location) {
                        analysis.locations.append(location)
                    }
                case .organizationName:
                    let org = String(text[tokenRange])
                    if !org.isEmpty {
                        analysis.entities.append(org)
                    }
                case .personalName:
                    let name = String(text[tokenRange])
                    if !name.isEmpty {
                        analysis.entities.append(name)
                    }
                default:
                    break
                }
            }
            return true
        }
        
        // Extract sentiment using built-in sentiment analysis
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, tokenRange in
            if let tag = tag {
                let score = Double(tag.rawValue) ?? 0.0
                if score > 0.3 {
                    analysis.sentiment = .positive
                } else if score < -0.3 {
                    analysis.sentiment = .negative
                }
            }
            return true
        }
        
        // Extract key topics using lexical analysis
        var importantWords: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange]).lowercased()
                // Focus on nouns, adjectives, and verbs
                if tag == .noun || tag == .adjective || tag == .verb {
                    if word.count > 3 && !isStopWord(word) {
                        importantWords.append(word)
                    }
                }
            }
            return true
        }
        analysis.keyTopics = Array(Set(importantWords)).prefix(10).map { $0 }
        
        // Extract amounts with better pattern matching
        let amountPatterns = [
            #"\$?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#,  // $1,234.56
            #"(\d+)\s*(?:dollars?|USD|usd)"#,            // 100 dollars
            #"(\d+\.?\d{0,2})\s*(?:per|/)\s*(?:day|night|person)"#  // 50 per day
        ]
        
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if match.numberOfRanges > 1,
                       let amountRange = Range(match.range(at: 1), in: text) {
                        let amountString = String(text[amountRange]).replacingOccurrences(of: ",", with: "")
                        if let amount = Double(amountString) {
                            analysis.amounts.append(amount)
                        }
                    }
                }
            }
        }
        
        // Extract preferences (likes, wants, needs, etc.)
        let preferenceKeywords = ["like", "love", "enjoy", "prefer", "want", "need", "interested", "favorite", "best"]
        for keyword in preferenceKeywords {
            if text.lowercased().contains(keyword) {
                // Extract the object of preference
                if let range = text.lowercased().range(of: keyword) {
                    let afterKeyword = text[range.upperBound...]
                    let words = afterKeyword.components(separatedBy: .whitespacesAndNewlines).prefix(3)
                    analysis.preferences.append(contentsOf: words.filter { $0.count > 2 })
                }
            }
        }
        
        // Detect question type
        if text.contains("?") {
            if text.lowercased().contains("how much") || text.lowercased().contains("what's the cost") {
                analysis.questionType = "cost"
            } else if text.lowercased().contains("when") {
                analysis.questionType = "time"
            } else if text.lowercased().contains("where") {
                analysis.questionType = "location"
            } else if text.lowercased().contains("why") {
                analysis.questionType = "reason"
            } else if text.lowercased().contains("how") {
                analysis.questionType = "method"
            }
        }
        
        return analysis
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "as", "is", "was", "are", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "should", "could", "may", "might", "must", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "what", "which", "who", "whom", "whose", "where", "when", "why", "how"]
        return stopWords.contains(word.lowercased())
    }
    
    private func detectFollowUpQuestion(message: String, history: ArraySlice<ChatMessage>) -> Bool {
        // Use NLP to detect if this is a follow-up
        let followUpIndicators = ["that", "this", "it", "them", "those", "also", "and", "what about", "how about", "tell me more", "more about", "explain", "elaborate", "can you", "could you"]
        
        if followUpIndicators.contains(where: { message.lowercased().contains($0) }) {
            return true
        }
        
        // Check if message references previous topics
        if !history.isEmpty {
            let lastTopics = history.compactMap { msg -> [String]? in
                if !msg.isUser {
                    return analyzeTripNotes(msg.text).keywords
                }
                return nil
            }.flatMap { $0 }
            
            let currentWords = Set(message.lowercased().components(separatedBy: .whitespaces))
            let topicWords = Set(lastTopics.map { $0.lowercased() })
            
            // If there's significant overlap, it's likely a follow-up
            let intersection = currentWords.intersection(topicWords)
            return intersection.count > 0
        }
        
        return false
    }
    
    private enum ChatIntent {
        case greeting
        case budget
        case suggestions
        case itinerary
        case expenses
        case weather
        case packing
        case destinations
        case general
    }
    
    private func detectIntent(from message: String, context: ConversationContext) -> ChatIntent {
        // Enhanced keyword detection with context awareness
        let budgetKeywords = ["budget", "money", "cost", "spend", "expensive", "cheap", "afford", "price", "dollar", "currency", "how much", "costs"]
        let suggestionKeywords = ["suggest", "recommend", "idea", "what should", "what can", "tips", "advice", "recommendation", "best", "top", "must see", "must do"]
        let itineraryKeywords = ["itinerary", "schedule", "plan", "activities", "what to do", "when", "day", "time", "activity", "event"]
        let expenseKeywords = ["expense", "spent", "spending", "costs", "receipt", "paid", "bought", "purchase"]
        let weatherKeywords = ["weather", "temperature", "rain", "sunny", "forecast", "climate", "hot", "cold", "warm", "cool"]
        let packingKeywords = ["pack", "packing", "bring", "luggage", "suitcase", "what to pack", "items", "clothes", "clothing"]
        let destinationKeywords = ["destination", "place", "location", "where", "city", "country", "visit", "go", "travel to"]
        let greetingKeywords = ["hi", "hello", "hey", "good morning", "good afternoon", "good evening", "greetings"]
        let questionKeywords = ["what", "how", "why", "when", "where", "who", "which", "can you", "could you", "would you"]
        let comparisonKeywords = ["compare", "difference", "better", "best", "versus", "vs", "or"]
        
        // Check for follow-up questions first
        if context.followUpQuestion {
            // Determine follow-up intent from context
            if context.previousTopics.contains(where: { budgetKeywords.contains($0) }) {
                return .budget
            } else if context.previousTopics.contains(where: { suggestionKeywords.contains($0) }) {
                return .suggestions
            }
        }
        
        // Primary intent detection
        if greetingKeywords.contains(where: message.contains) && !questionKeywords.contains(where: message.contains) {
            return .greeting
        } else if budgetKeywords.contains(where: message.contains) {
            return .budget
        } else if suggestionKeywords.contains(where: message.contains) {
            return .suggestions
        } else if itineraryKeywords.contains(where: message.contains) {
            return .itinerary
        } else if expenseKeywords.contains(where: message.contains) {
            return .expenses
        } else if weatherKeywords.contains(where: message.contains) {
            return .weather
        } else if packingKeywords.contains(where: message.contains) {
            return .packing
        } else if destinationKeywords.contains(where: message.contains) {
            return .destinations
        } else if comparisonKeywords.contains(where: message.contains) {
            return .suggestions // Comparisons usually want suggestions
        } else if questionKeywords.contains(where: message.contains) {
            return .general // Open-ended questions
        } else {
            return .general
        }
    }
    
    private func generateStructuredResponse(
        intent: ChatIntent,
        understanding: ComprehensiveUnderstanding,
        trip: TripModel,
        context: ConversationContext,
        originalMessage: String = ""
    ) -> AIStructuredResponse {
        // Generate base response based on intent
        let baseResponse: String
        var itineraryItems: [StructuredItineraryItem]? = nil
        var suggestions: [StructuredSuggestion]? = nil
        let documents: [StructuredDocument]? = nil
        var actions: [StructuredAction]? = nil
        
        switch intent {
        case .greeting:
            baseResponse = generateGreetingResponse(for: trip, context: context, understanding: understanding)
        case .budget:
            baseResponse = generateBudgetResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
            suggestions = generateBudgetSuggestions(for: trip, understanding: understanding)
        case .suggestions:
            baseResponse = generateSuggestionsResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
            suggestions = generateActionableSuggestions(for: trip, understanding: understanding, context: context)
        case .itinerary:
            let itineraryResult = generateItineraryResponseWithStructure(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding, originalMessage: originalMessage)
            baseResponse = itineraryResult.text
            itineraryItems = itineraryResult.items
            actions = itineraryResult.actions
        case .expenses:
            baseResponse = generateExpensesResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .weather:
            baseResponse = generateWeatherResponse(for: trip, context: context, understanding: understanding)
        case .packing:
            baseResponse = generatePackingResponse(for: trip, context: context, understanding: understanding)
        case .destinations:
            baseResponse = generateDestinationsResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
            suggestions = generateDestinationSuggestions(for: trip, understanding: understanding, context: context)
        case .general:
            baseResponse = generateGeneralResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        }
        
        // Enhance response based on understanding
        let enhancedText = enhanceResponse(
            baseResponse: baseResponse,
            understanding: understanding,
            trip: trip
        )
        
        return AIResponseParser.createStructuredResponse(
            text: enhancedText,
            itineraryItems: itineraryItems,
            suggestions: suggestions,
            documents: documents,
            actions: actions
        )
    }
    
    private func generateSophisticatedResponse(
        intent: ChatIntent,
        understanding: ComprehensiveUnderstanding,
        trip: TripModel,
        context: ConversationContext
    ) -> String {
        // Generate base response based on intent
        let baseResponse: String
        switch intent {
        case .greeting:
            baseResponse = generateGreetingResponse(for: trip, context: context, understanding: understanding)
        case .budget:
            baseResponse = generateBudgetResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .suggestions:
            baseResponse = generateSuggestionsResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .itinerary:
            baseResponse = generateItineraryResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .expenses:
            baseResponse = generateExpensesResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .weather:
            baseResponse = generateWeatherResponse(for: trip, context: context, understanding: understanding)
        case .packing:
            baseResponse = generatePackingResponse(for: trip, context: context, understanding: understanding)
        case .destinations:
            baseResponse = generateDestinationsResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        case .general:
            baseResponse = generateGeneralResponse(for: trip, message: understanding.extractedInfo, context: context, understanding: understanding)
        }
        
        // Enhance response based on understanding
        return enhanceResponse(
            baseResponse: baseResponse,
            understanding: understanding,
            trip: trip
        )
    }
    
    private func enhanceResponse(
        baseResponse: String,
        understanding: ComprehensiveUnderstanding,
        trip: TripModel
    ) -> String {
        var response = baseResponse
        
        // Add conversational connectors based on style
        switch understanding.responseStyle {
        case .friendly:
            if !response.hasPrefix("😊") && !response.hasPrefix("🌟") && !response.hasPrefix("Great") {
                let connectors = ["Great question! ", "That's a good question! ", "I'd be happy to help! ", ""]
                response = (connectors.randomElement() ?? "") + response
            }
        case .analytical:
            if !response.contains("Based on") && !response.contains("Let me") && !response.contains("I'd suggest") {
                let connectors = ["Let me break this down for you: ", "Here's my analysis: ", "Let me think through this: "]
                response = (connectors.randomElement() ?? "") + response
            }
        case .encouraging:
            // Add encouraging phrases
            if !response.contains("!") && !response.contains("great") && !response.contains("wonderful") {
                let encouragers = ["That's great! ", "Wonderful question! ", "I love that you're thinking about this! "]
                response = (encouragers.randomElement() ?? "") + response
            }
        case .professional:
            response = response.replacingOccurrences(of: "I'd", with: "I would")
            response = response.replacingOccurrences(of: "don't", with: "do not")
            response = response.replacingOccurrences(of: "can't", with: "cannot")
        default:
            break
        }
        
        // Add follow-up questions for exploratory personality
        if understanding.userPersonality == .exploratory && !response.contains("?") && !response.hasSuffix("?") {
            let followUps = [
                " Would you like me to elaborate on any of this?",
                " Is there a specific aspect you'd like to explore further?",
                " What other questions do you have about this?",
                " Would you like more details on any particular point?"
            ]
            response += followUps.randomElement() ?? ""
        }
        
        // Add urgency handling
        if understanding.urgency == .urgent {
            response = "I understand this is important and time-sensitive. " + response
        } else if understanding.urgency == .relaxed {
            if !response.contains("take your time") {
                response += " No rush - take your time to think it over."
            }
        }
        
        // Add context-aware transitions for multi-intent messages
        if understanding.secondaryIntents.count > 1 {
            response += " I can also help with \(understanding.secondaryIntents.prefix(2).map { intentName($0) }.joined(separator: " and ")) if you'd like."
        }
        
        return response
    }
    
    private func intentName(_ intent: ChatIntent) -> String {
        switch intent {
        case .budget: return "budget planning"
        case .suggestions: return "suggestions"
        case .itinerary: return "itinerary planning"
        case .expenses: return "expense tracking"
        case .weather: return "weather planning"
        case .packing: return "packing lists"
        case .destinations: return "destination planning"
        default: return "other aspects"
        }
    }
    
    private func generateGreetingResponse(
        for trip: TripModel,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        if context.followUpQuestion {
            let personalizedGreetings = [
                "Hi again! 👋 I'm here to continue helping with your \(trip.name) trip. What would you like to explore next?",
                "Welcome back! 🌟 I see we were discussing \(context.previousTopics.prefix(2).joined(separator: " and ")). What else can I help you with?",
                "Great to have you back! 💫 Let's continue planning your amazing \(trip.duration)-day trip to \(trip.name). What's on your mind?"
            ]
            return personalizedGreetings.randomElement() ?? personalizedGreetings[0]
        }
        
        // Personalized greeting based on trip status
        let daysUntil = trip.isUpcoming ? Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0 : 0
        
        var greeting = "👋 Hello! I'm your AI trip assistant, and I'm here to help make your \(trip.name) trip absolutely amazing!"
        
        if trip.isUpcoming && daysUntil > 0 {
            greeting += " Your \(trip.duration)-day adventure starts \(daysUntil == 1 ? "tomorrow" : "in \(daysUntil) days") - how exciting!"
        } else if trip.isCurrent {
            greeting += " You're currently on your trip - I hope it's going wonderfully!"
        } else {
            greeting += " I see you're planning a \(trip.duration)-day journey."
        }
        
        // Add personalized touch based on trip data
        if let budget = trip.budget {
            greeting += " I notice you have a budget of \(formatCurrency(budget)) set, which is great for planning!"
        }
        
        if (trip.destinations?.count ?? 0) > 0 {
            greeting += " You've already added some destinations - excellent start!"
        }
        
        greeting += " What would you like to work on today? I can help with planning, budgeting, suggestions, itinerary, expenses, packing, and much more!"
        
        return greeting
    }
    
    private func generateBudgetResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        guard let budget = trip.budget, budget > 0 else {
            var response = "💡 I notice you haven't set a budget yet for your trip. "
            
            // Provide helpful estimation if we have trip details
            if trip.duration > 0 {
                let estimatedBudget = estimateBudget(for: trip)
                let dailyEstimate = estimatedBudget / Double(trip.duration)
                response += "Based on your \(trip.duration)-day \(trip.category.lowercased()) trip, I'd estimate you might need around \(formatCurrency(estimatedBudget)) total, which breaks down to approximately \(formatCurrency(dailyEstimate)) per day. "
                
                // Add category-specific insights
                switch trip.category.lowercased() {
                case "business":
                    response += "For business trips, typical daily costs include: accommodation ($150-300), meals ($50-100), transportation ($30-80), and incidentals ($20-50). "
                case "luxury", "premium":
                    response += "For a luxury trip, you might expect: premium accommodations ($300-800/night), fine dining ($100-300/day), private transportation ($100-200/day), and exclusive experiences ($200-500/day). "
                case "budget", "backpacking":
                    response += "For budget travel, you can typically manage with: hostels or budget hotels ($30-80/night), local food ($20-40/day), public transport ($10-30/day), and free/low-cost activities ($10-30/day). "
                default:
                    response += "This estimate includes accommodation, food, transportation, activities, and a buffer for unexpected expenses. "
                }
            }
            
            response += "Setting a budget helps you track expenses and stay on track financially. Would you like me to help you create a detailed budget breakdown by category?"
            return response
        }
        
        let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
        let remaining = budget - totalExpenses
        let percentage = (totalExpenses / budget) * 100
        let dailySpent = totalExpenses / Double(max(trip.duration, 1))
        let dailyBudget = budget / Double(trip.duration)
        let expenseCount = trip.expenses?.count ?? 0
        
        // Check if user mentioned specific amounts
        if let mentionedAmount = message.amounts.first {
            return "💰 I see you mentioned \(formatCurrency(mentionedAmount)). Let me put that in context: Your current budget is \(formatCurrency(budget)), and you've spent \(formatCurrency(totalExpenses)) so far (\(Int(percentage))%). \(formatCurrency(mentionedAmount)) would represent \(Int((mentionedAmount / budget) * 100))% of your total budget. \(mentionedAmount > remaining ? "That's more than your remaining \(formatCurrency(remaining))." : "That fits within your remaining budget of \(formatCurrency(remaining)).") Would you like me to help you plan how to allocate this amount?"
        }
        
        // Comprehensive budget analysis
        if percentage > 90 {
            return "⚠️ **Budget Alert!** You've used \(Int(percentage))% of your \(formatCurrency(budget)) budget, with only \(formatCurrency(remaining)) remaining. At your current daily spending rate of \(formatCurrency(dailySpent)), you're significantly above your daily budget of \(formatCurrency(dailyBudget)). I'd recommend: 1) Reviewing all expenses to identify areas to cut back, 2) Prioritizing essential items only, 3) Looking for free or low-cost alternatives. Would you like me to analyze your spending patterns and suggest specific areas to reduce costs?"
        } else if percentage > 80 {
            return "⚠️ **Budget Warning:** You've used \(Int(percentage))% of your budget (\(formatCurrency(totalExpenses)) of \(formatCurrency(budget))), leaving \(formatCurrency(remaining)). Your daily average of \(formatCurrency(dailySpent)) is \(dailySpent > dailyBudget ? "above" : "at") your daily budget of \(formatCurrency(dailyBudget)). To stay on track, try to keep future daily spending under \(formatCurrency(remaining / Double(max(1, trip.duration - (Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0))))). I can help you create a spending plan for the remainder of your trip."
        } else if percentage > 50 {
            return "📊 **Budget Status:** You're doing well! You've spent \(formatCurrency(totalExpenses)) (\(Int(percentage))%) of your \(formatCurrency(budget)) budget, with \(formatCurrency(remaining)) remaining. Your daily average of \(formatCurrency(dailySpent)) is \(dailySpent > dailyBudget ? "slightly above" : "below") your daily budget of \(formatCurrency(dailyBudget)), which is \(dailySpent > dailyBudget ? "something to watch" : "excellent"). You have \(expenseCount) expense\(expenseCount > 1 ? "s" : "") logged. Keep tracking to maintain this good pace!"
        } else if percentage > 0 {
            return "✅ **Excellent Budget Management!** You've only used \(Int(percentage))% of your budget so far (\(formatCurrency(totalExpenses)) of \(formatCurrency(budget))), leaving you with \(formatCurrency(remaining)) - that's \(Int((remaining / budget) * 100))% still available! Your daily average of \(formatCurrency(dailySpent)) is well below your daily budget of \(formatCurrency(dailyBudget)), which gives you flexibility. You're tracking \(expenseCount) expense\(expenseCount > 1 ? "s" : "") - great job staying organized!"
        } else {
            return "💰 **Budget Set:** Your budget is \(formatCurrency(budget)) for this \(trip.duration)-day trip, which averages to \(formatCurrency(dailyBudget)) per day. You haven't logged any expenses yet. I'd suggest: 1) Start tracking expenses as you spend, 2) Use the receipt scanner for easy logging, 3) Review your spending weekly to stay on track. I can also help you break down your budget by category (accommodation, food, activities, etc.) if that would be helpful!"
        }
    }
    
    private func estimateBudget(for trip: TripModel) -> Double {
        // Rough estimation based on trip details
        let baseDaily = 150.0 // Base daily cost
        var multiplier = 1.0
        
        switch trip.category.lowercased() {
        case "business":
            multiplier = 2.0
        case "luxury", "premium":
            multiplier = 2.5
        case "budget", "backpacking":
            multiplier = 0.6
        case "adventure":
            multiplier = 1.3
        default:
            multiplier = 1.0
        }
        
        return baseDaily * Double(trip.duration) * multiplier
    }
    
    private func generateSuggestionsResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        var suggestions: [String] = []
        
        // Personalize based on user's actual message
        if !message.preferences.isEmpty {
            let prefs = message.preferences.joined(separator: ", ")
            suggestions.append("🌟 Based on your interest in \(prefs), I'd suggest: 1) Researching local spots that match these interests, 2) Adding them to your itinerary, 3) Checking reviews and ratings before booking.")
        }
        
        if !message.locations.isEmpty {
            let locs = message.locations.joined(separator: ", ")
            suggestions.append("📍 For \(locs), I recommend: 1) Checking the best times to visit, 2) Finding nearby attractions, 3) Looking for local experiences and tours.")
        }
        
        // Category-based suggestions
        switch trip.category.lowercased() {
        case "business":
            suggestions.append("💼 For your business trip, I recommend: keeping receipts organized for expense reports, planning for time zone differences, packing professional attire, and checking if your hotel has a business center. Also, consider booking restaurants near your meetings!")
        case "vacation", "leisure":
            suggestions.append("🏖️ For a relaxing vacation: don't over-schedule! Leave time for spontaneous discoveries. Try local restaurants, visit markets, take time to just enjoy the moment, and maybe find a nice spot to watch the sunset.")
        case "adventure":
            suggestions.append("⛰️ Adventure trip tips: Check weather conditions before activities, pack appropriate gear (layers are key!), always share your itinerary with someone back home for safety, and consider travel insurance for adventure activities.")
        default:
            suggestions.append("🌟 Make the most of your trip by mixing planned activities with spontaneous exploration. Try local food, talk to locals, capture memories, and don't forget to take breaks!")
        }
        
        // Duration-based personalized suggestions
        if trip.duration > 14 {
            suggestions.append("📅 For your \(trip.duration)-day trip, consider: packing versatile clothing that can be layered, planning rest days (every 3-4 days), booking accommodations in advance for better rates, and creating a flexible itinerary that allows for changes.")
        } else if trip.duration > 7 {
            suggestions.append("📅 For your week-long trip: pack versatile clothing, plan a mix of activities and relaxation time, book popular spots in advance, and leave one day completely unplanned for spontaneity!")
        } else {
            suggestions.append("📅 For your \(trip.duration)-day trip: focus on 2-3 key experiences, book popular spots in advance, pack light, and don't try to see everything - quality over quantity!")
        }
        
        // Budget-based suggestions
        if let budget = trip.budget {
            let dailyBudget = budget / Double(trip.duration)
            suggestions.append("💰 With a daily budget of \(formatCurrency(dailyBudget)), I'd suggest allocating: 40% for accommodation, 30% for food and drinks, 20% for activities and experiences, and 10% for emergencies or souvenirs.")
        } else if let amount = context.mentionedAmounts.last {
            suggestions.append("💰 Based on your mention of \(formatCurrency(amount)), that could work well for your trip! I'd suggest creating a budget breakdown to see how it fits with your \(trip.duration)-day plan.")
        }
        
        // Use context from conversation
        if context.followUpQuestion && !context.previousTopics.isEmpty {
            suggestions.append("💡 Following up on our previous discussion, here are some additional ideas that might interest you based on what we talked about.")
        }
        
        return suggestions.isEmpty ? "🌟 I'd be happy to provide suggestions! Could you tell me more about what you're interested in - activities, places to visit, or specific experiences?" : suggestions.joined(separator: "\n\n")
    }
    
    private func generateItineraryResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        let activityCount = trip.itinerary?.count ?? 0
        
        // Check if user mentioned specific activities
        if !message.keyTopics.isEmpty && activityCount == 0 {
            let topics = message.keyTopics.prefix(2).joined(separator: " and ")
            return "📅 I see you're interested in \(topics)! That's a great start for your itinerary. Based on your \(trip.duration)-day trip, I'd suggest: 1) Creating activities around \(topics), 2) Spreading them across different days, 3) Leaving time for spontaneous exploration. Would you like me to help you add these to your itinerary?"
        }
        
        if activityCount == 0 {
            var response = "📅 You haven't added any activities to your itinerary yet. I can help you plan! Based on your \(trip.duration)-day trip, I'd suggest creating a balanced schedule with 2-3 activities per day."
            
            // Add personalized suggestions based on understanding
            if !message.preferences.isEmpty {
                response += " I noticed you're interested in \(message.preferences.joined(separator: ", ")) - we could build activities around those interests!"
            }
            
            response += " Would you like me to suggest some activities based on your trip details?"
            return response
        } else {
            if message.questionType == "time" {
                return "⏰ For timing your activities: I'd suggest spacing them out throughout the day, leaving 2-3 hours between major activities, and planning rest periods. You have \(activityCount) activities planned - that's a good balance for a \(trip.duration)-day trip! Would you like help optimizing the timing or adding more activities?"
            }
            
            // Provide detailed itinerary analysis
            var response = "📅 Great! You have \(activityCount) activity\(activityCount > 1 ? "ies" : "") planned for your \(trip.duration)-day trip."
            
            let activitiesPerDay = Double(activityCount) / Double(trip.duration)
            if activitiesPerDay > 3 {
                response += " That's quite a packed schedule - make sure to leave time for rest and spontaneity!"
            } else if activitiesPerDay < 1 {
                response += " You have room to add more activities if you'd like."
            } else {
                response += " That's a nice balanced pace!"
            }
            
            response += " I can help you: 1) Add more activities, 2) Optimize your schedule, 3) Balance activities with free time. What would be most helpful?"
            return response
        }
    }
    
    private func generateExpensesResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        let expenseCount = trip.expenses?.count ?? 0
        let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
        
        // Check if user mentioned specific amounts
        if let amount = message.amounts.first {
            var response = "💰 I see you mentioned \(formatCurrency(amount)). "
            
            if expenseCount > 0 {
                response += "You've already logged \(expenseCount) expense\(expenseCount > 1 ? "s" : "") totaling \(formatCurrency(totalExpenses)). "
                
                if let budget = trip.budget {
                    let newTotal = totalExpenses + amount
                    let newPercentage = (newTotal / budget) * 100
                    response += "If you add this expense, you'll have spent \(formatCurrency(newTotal)) (\(Int(newPercentage))% of your budget). "
                }
            }
            
            response += "Would you like to add this as a new expense, or are you asking about how this amount fits into your budget?"
            return response
        }
        
        if expenseCount == 0 {
            var response = "💳 You haven't logged any expenses yet. "
            
            if let budget = trip.budget {
                response += "With your budget of \(formatCurrency(budget)), tracking expenses will help you stay on track. "
            }
            
            response += "I can help you: 1) Add expenses manually, 2) Scan receipts for automatic entry, 3) Categorize expenses, 4) Track spending against your budget. Would you like to get started?"
            return response
        } else {
            let averageExpense = totalExpenses / Double(expenseCount)
            let categories = Set(trip.expenses?.map { $0.category } ?? [])
            let largestExpense = trip.expenses?.max(by: { $0.amount < $1.amount })
            
            var response = "💳 **Expense Summary:** You've logged \(expenseCount) expense\(expenseCount > 1 ? "s" : "") totaling \(formatCurrency(totalExpenses)). "
            response += "That's an average of \(formatCurrency(averageExpense)) per expense. "
            
            if categories.count > 1 {
                response += "You've spent across \(categories.count) different categories, which shows good variety in your spending. "
            }
            
            if let largest = largestExpense {
                response += "Your largest expense was \(formatCurrency(largest.amount)) for \(largest.title). "
            }
            
            if let budget = trip.budget {
                let percentage = (totalExpenses / budget) * 100
                response += "You've used \(Int(percentage))% of your \(formatCurrency(budget)) budget. "
            }
            
            response += "Would you like me to: 1) Analyze your spending patterns, 2) Show category breakdowns, 3) Suggest ways to optimize spending?"
            return response
        }
    }
    
    private func generateWeatherResponse(
        for trip: TripModel,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        if trip.isUpcoming {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
            var response = "🌤️ Your trip starts \(daysUntil == 0 ? "today" : daysUntil == 1 ? "tomorrow" : "in \(daysUntil) days")! "
            
            if daysUntil <= 7 {
                response += "I highly recommend checking the weather forecast for your destinations now - this is crucial for last-minute packing decisions. "
            } else {
                response += "I recommend checking the weather forecast for your destinations. "
            }
            
            response += "This will help you: 1) Pack appropriately for the conditions, 2) Plan outdoor activities on good weather days, 3) Adjust your itinerary if needed. "
            
            if (trip.destinations?.count ?? 0) > 1 {
                response += "Since you're visiting multiple destinations, weather can vary significantly between locations. "
            }
            
            response += "You can view detailed forecasts in the Weather tab!"
            return response
        } else if trip.isCurrent {
            return "🌤️ You're on your trip now! Check the weather tab for current conditions and forecasts. This helps you plan your daily activities and decide what to do each day. Pro tip: Check the weather each morning to plan your day accordingly. Stay safe and enjoy your adventure!"
        } else {
            return "🌤️ For weather information, check the Weather tab in your trip details. It shows forecasts for all your destinations! This is especially helpful for: 1) Planning what to pack, 2) Deciding which activities to schedule, 3) Preparing for any weather-related challenges. Would you like help planning around weather conditions?"
        }
    }
    
    private func generatePackingResponse(
        for trip: TripModel,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        let packingCount = trip.packingList?.count ?? 0
        
        if packingCount == 0 {
            var response = "🧳 You haven't created a packing list yet. I can help! Based on your \(trip.duration)-day \(trip.category.lowercased()) trip to \(trip.name), here's my approach: "
            
            response += "1) **Check weather first** - This determines what you'll actually need. "
            response += "2) **Consider your trip type** - \(trip.category) trips have specific requirements. "
            response += "3) **Think about activities** - What will you be doing? "
            
            // Add category-specific packing tips
            switch trip.category.lowercased() {
            case "business":
                response += "For business trips, prioritize: professional attire, comfortable shoes for walking, a good bag for documents, and adapters for your devices. "
            case "adventure":
                response += "For adventure trips, think about: layers for changing weather, sturdy footwear, safety gear, and backup supplies. "
            case "vacation", "leisure":
                response += "For vacation, focus on: versatile clothing, comfortable shoes, swimwear if applicable, and items for relaxation. "
            default:
                break
            }
            
            response += "Would you like me to suggest some essential items based on your trip details?"
            return response
        } else {
            var response = "🧳 Great! You have \(packingCount) item\(packingCount > 1 ? "s" : "") on your packing list. "
            
            // Provide packing optimization tips
            if packingCount > trip.duration * 3 {
                response += "That's quite a lot of items for a \(trip.duration)-day trip - you might want to consider packing lighter for easier travel. "
            } else if packingCount < trip.duration {
                response += "That's a minimal list - make sure you have all the essentials covered! "
            } else {
                response += "That's a good amount for your trip duration. "
            }
            
            response += "Before finalizing: 1) Check the weather forecast to ensure you're prepared, 2) Consider your planned activities, 3) Think about versatility - can items serve multiple purposes? "
            response += "Need help: adding more items, organizing by category, or creating a checklist?"
            return response
        }
    }
    
    private func generateDestinationsResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        let destinationCount = trip.destinations?.count ?? 0
        
        // Check if user mentioned specific locations
        if !message.locations.isEmpty {
            let locs = message.locations.joined(separator: ", ")
            var response = "📍 I see you mentioned \(locs)! Those sound like great places to visit. "
            
            if destinationCount > 0 {
                response += "You already have \(destinationCount) destination\(destinationCount > 1 ? "s" : "") planned. "
            }
            
            response += "I can help you: 1) **Add \(locs) to your destinations** - This will enable better planning and recommendations, 2) **Find activities at these locations** - I can suggest things to do, places to see, and experiences to have, 3) **Plan your itinerary around them** - We can create a schedule that makes the most of your time there. "
            
            if destinationCount > 0 {
                response += "Would you like to see how \(locs) fits with your existing destinations?"
            } else {
                response += "Would you like to start by adding \(locs) to your trip?"
            }
            
            return response
        }
        
        if destinationCount == 0 {
            var response = "📍 You haven't added any destinations yet. Adding destinations is one of the most important steps in trip planning because it helps me: "
            response += "1) Provide location-specific recommendations, 2) Help with itinerary planning, 3) Suggest activities and experiences, 4) Check weather forecasts, 5) Estimate travel times and costs. "
            
            if !message.preferences.isEmpty {
                response += "I noticed you're interested in \(message.preferences.joined(separator: ", ")) - I can suggest destinations that match these interests! "
            }
            
            response += "Would you like help finding places to visit, or do you already have some destinations in mind?"
            return response
        } else {
            let destinationNames = trip.destinations?.prefix(3).map { $0.name }.joined(separator: ", ") ?? ""
            var response = "📍 You're visiting \(destinationCount) destination\(destinationCount > 1 ? "s" : ""): \(destinationNames)\(destinationCount > 3 ? " and more" : ""). Great planning! "
            
            if destinationCount > 3 {
                response += "That's quite an ambitious itinerary - make sure to allow enough time at each place to truly experience them. "
            }
            
            response += "I can help you: 1) **Get suggestions for activities** at these locations, 2) **Plan your itinerary** to optimize your time, 3) **Find the best times to visit** each place, 4) **Estimate travel between destinations**. What would you like to focus on?"
            return response
        }
    }
    
    private func generateGeneralResponse(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding
    ) -> String {
        // Personalized response based on what user actually said
        if !message.locations.isEmpty {
            let locationList = message.locations.joined(separator: ", ")
            return "🗺️ I see you mentioned \(locationList). Those sound like great places! Based on your \(trip.duration)-day trip, I'd suggest: 1) Adding them to your destinations for better planning, 2) Creating itinerary items for each location, and 3) Checking weather forecasts for those areas. Would you like me to help you add \(message.locations.first ?? "these places") to your trip?"
        }
        
        if let amount = message.amounts.first {
            let daysCovered = Int(amount / 150)
            return "💰 I see you mentioned \(formatCurrency(amount)). That's helpful context! For your \(trip.duration)-day trip to \(trip.name), \(formatCurrency(amount)) could cover \(daysCovered) days of moderate spending. Would you like me to help you create a budget breakdown or track expenses around this amount?"
        }
        
        if !message.preferences.isEmpty {
            let preferences = message.preferences.joined(separator: ", ")
            return "🌟 I notice you're interested in \(preferences). That's great! For your \(trip.name) trip, I can help you: 1) Find activities related to \(preferences), 2) Suggest places that match your interests, and 3) Plan your itinerary around these preferences. What would you like to explore first?"
        }
        
        if let questionType = message.questionType {
            switch questionType {
            case "cost":
                return "💰 You're asking about costs! For your \(trip.duration)-day trip, I can help estimate expenses. Based on your trip category (\(trip.category)), I'd estimate around \(formatCurrency(estimateBudget(for: trip))) total, or \(formatCurrency(estimateBudget(for: trip) / Double(trip.duration))) per day. Would you like a detailed breakdown by category?"
            case "time":
                return "⏰ You're asking about timing! Your trip is \(trip.duration) days, from \(formatDate(trip.startDate)) to \(formatDate(trip.endDate)). \(trip.isUpcoming ? "It's coming up soon!" : trip.isCurrent ? "You're on it now!" : "It's in the past.") I can help you plan activities, create an itinerary, or set reminders. What would be most helpful?"
            case "location":
                return "📍 You're asking about locations! \(trip.destinations?.isEmpty ?? true ? "You haven't added destinations yet." : "You have \(trip.destinations?.count ?? 0) destinations planned.") I can help you: 1) Add new destinations, 2) Get suggestions for places to visit, 3) Plan activities at your destinations. What would you like to do?"
            case "method":
                return "💡 You're asking how to do something! I'm here to guide you. Based on your \(trip.name) trip, I can help with: planning your itinerary, managing your budget, tracking expenses, packing suggestions, and more. What specific aspect would you like help with?"
            default:
                break
            }
        }
        
        // Use sentiment to personalize response
        if message.sentiment == .positive {
            var response = "😊 I can sense your excitement about \(trip.name)! That's wonderful! "
            
            if understanding.userPersonality == .exploratory {
                response += "I love that you're curious and want to explore. "
            }
            
            response += "Based on what you've shared, I'm here to help make your \(trip.duration)-day trip even better. I can assist with: detailed planning, budget optimization, activity suggestions, itinerary creation, and personalized recommendations. What would you like to focus on?"
            return response
        } else if message.sentiment == .negative {
            return "🤔 I understand you might have some concerns. Don't worry - I'm here to help! For your \(trip.name) trip, I can help you: plan better, manage your budget effectively, find great activities, and ensure everything goes smoothly. What specific challenge would you like help with? I'm here to make your trip planning stress-free."
        }
        
        // Extract key topics from user message and respond to them
        if !message.keyTopics.isEmpty {
            let topics = message.keyTopics.prefix(3).joined(separator: ", ")
            var response = "💭 I see you're interested in \(topics). That's great context for your \(trip.name) trip! "
            
            // Add insights based on topics
            if message.keyTopics.contains(where: { ["hiking", "outdoor", "nature"].contains($0.lowercased()) }) {
                response += "For outdoor activities, I'd recommend checking weather conditions and packing appropriate gear. "
            }
            
            response += "Based on this, I can help you: 1) Find activities related to \(topics), 2) Plan your itinerary around these interests, 3) Get personalized suggestions. What would you like to explore?"
            return response
        }
        
        // Use conversation context for better responses
        if !context.previousTopics.isEmpty && !understanding.conversationSummary.isEmpty {
            return "💡 Following up on our conversation about \(context.previousTopics.prefix(2).joined(separator: " and ")), I'm here to help with your \(trip.name) trip. I can assist with planning, budget tracking, suggestions, itinerary, expenses, weather, packing, and more. What specific aspect would you like to explore further?"
        }
        
        // Default intelligent response with personality
        var response = "🤔 I'm here to help! Based on your \(trip.name) trip, I can assist with: "
        
        let capabilities = ["planning", "budget tracking", "activity suggestions", "itinerary creation", "expense management", "weather planning", "packing lists"]
        response += capabilities.prefix(4).joined(separator: ", ")
        response += ", and much more. "
        
        if understanding.userPersonality == .detailed {
            response += "Since you like detailed information, I can provide comprehensive breakdowns and analysis. "
        } else if understanding.userPersonality == .direct {
            response += "I'll keep my responses concise and actionable. "
        }
        
        response += "What specific aspect would you like to know about?"
        return response
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatCurrency(_ amount: Double) -> String {
        // Use SettingsManager for consistent currency formatting
        return SettingsManager.shared.formatAmount(amount)
    }
    
    // MARK: - Structured Data Generation
    
    private struct ItineraryResponseResult {
        let text: String
        let items: [StructuredItineraryItem]?
        let actions: [StructuredAction]?
    }
    
    private func generateItineraryResponseWithStructure(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext,
        understanding: ComprehensiveUnderstanding,
        originalMessage: String = ""
    ) -> ItineraryResponseResult {
        let text = generateItineraryResponse(for: trip, message: message, context: context, understanding: understanding)
        
        // Generate structured itinerary items if user wants to create itinerary
        var items: [StructuredItineraryItem]? = nil
        var actions: [StructuredAction]? = nil
        
        // Check if user wants to create/generate itinerary
        let createKeywords = ["create", "generate", "plan", "make", "build", "develop", "detailed"]
        let messageLower = originalMessage.lowercased()
        
        // Check in previous topics, current message keywords, or the original message itself
        let wantsToCreate = context.previousTopics.contains(where: { topic in
            createKeywords.contains(where: { topic.lowercased().contains($0) })
        }) || message.keyTopics.contains(where: { topic in
            createKeywords.contains(where: { topic.lowercased().contains($0) })
        }) || createKeywords.contains(where: { messageLower.contains($0) })
        
        let isHowOrWhatQuestion = message.questionType == "method" || message.questionType == "what"
        
        // Always generate items for itinerary intent if:
        // 1. User explicitly wants to create/generate (most common case)
        // 2. It's a how/what question about itinerary
        // 3. Message contains both "itinerary"/"schedule" AND create keywords
        // 4. No itinerary exists yet (first time) - always generate for new trips
        let hasItineraryKeyword = messageLower.contains("itinerary") || messageLower.contains("schedule") || messageLower.contains("activities") || messageLower.contains("plan")
        let hasCreateAndItinerary = hasItineraryKeyword && createKeywords.contains(where: { messageLower.contains($0) })
        let isNewTrip = trip.itinerary?.isEmpty ?? true
        
        // Generate if: wants to create, has create+itinerary keywords, is how/what question, or is a new trip
        let shouldGenerate = wantsToCreate || hasCreateAndItinerary || isHowOrWhatQuestion || isNewTrip
        
        if shouldGenerate {
            items = generateStructuredItineraryItems(for: trip, message: message, context: context)
            if items != nil && !items!.isEmpty {
                actions = [
                    StructuredAction(
                        id: UUID().uuidString,
                        type: "create_itinerary",
                        data: ["count": "\(items!.count)"],
                        label: "Save \(items!.count) itinerary items"
                    )
                ]
            }
        }
        
        return ItineraryResponseResult(text: text, items: items, actions: actions)
    }
    
    private func generateStructuredItineraryItems(
        for trip: TripModel,
        message: AdvancedTextAnalysis,
        context: ConversationContext
    ) -> [StructuredItineraryItem]? {
        var items: [StructuredItineraryItem] = []
        let calendar = Calendar.current
        let startDate = trip.startDate
        
        // Generate sample itinerary based on trip duration and preferences
        let activitiesPerDay = 2
        let totalDays = trip.duration
        
        for day in 1...min(totalDays, 7) { // Limit to 7 days for now
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) else { continue }
            
            // Morning activity
            let morningActivity = generateActivityForDay(day: day, timeOfDay: "morning", trip: trip, message: message)
            items.append(StructuredItineraryItem(
                id: UUID().uuidString,
                day: day,
                date: ISO8601DateFormatter().string(from: date),
                title: morningActivity.title,
                details: morningActivity.details,
                time: "09:00",
                location: morningActivity.location,
                order: (day - 1) * activitiesPerDay,
                isBooked: false,
                bookingReference: nil
            ))
            
            // Afternoon activity
            let afternoonActivity = generateActivityForDay(day: day, timeOfDay: "afternoon", trip: trip, message: message)
            items.append(StructuredItineraryItem(
                id: UUID().uuidString,
                day: day,
                date: ISO8601DateFormatter().string(from: date),
                title: afternoonActivity.title,
                details: afternoonActivity.details,
                time: "14:00",
                location: afternoonActivity.location,
                order: (day - 1) * activitiesPerDay + 1,
                isBooked: false,
                bookingReference: nil
            ))
        }
        
        return items.isEmpty ? nil : items
    }
    
    private func generateActivityForDay(day: Int, timeOfDay: String, trip: TripModel, message: AdvancedTextAnalysis) -> (title: String, details: String, location: String) {
        let category = trip.category.lowercased()
        let locations = message.locations.isEmpty ? (trip.destinations?.map { $0.name } ?? []) : message.locations
        
        let location = locations.randomElement() ?? "Destination"
        
        var activities: [(title: String, details: String)] = []
        
        switch category {
        case "business":
            activities = [
                ("Business Meeting", "Important business discussion"),
                ("Networking Event", "Connect with industry professionals"),
                ("Client Presentation", "Present your proposal"),
                ("Workshop", "Learn new skills")
            ]
        case "vacation", "leisure":
            activities = [
                ("Beach Time", "Relax and enjoy the sun"),
                ("Local Market Visit", "Explore local culture and food"),
                ("Sightseeing Tour", "Discover famous landmarks"),
                ("Spa & Relaxation", "Unwind and rejuvenate")
            ]
        case "adventure":
            activities = [
                ("Hiking Adventure", "Explore nature trails"),
                ("Water Sports", "Try exciting water activities"),
                ("Mountain Climbing", "Challenge yourself"),
                ("Wildlife Safari", "See amazing wildlife")
            ]
        default:
            activities = [
                ("City Tour", "Explore the city highlights"),
                ("Museum Visit", "Learn about local history"),
                ("Local Restaurant", "Try authentic cuisine"),
                ("Shopping", "Find unique souvenirs")
            ]
        }
        
        let activity = activities.randomElement() ?? ("Activity", "Enjoy your time")
        
        return (title: activity.title, details: activity.details, location: location)
    }
    
    private func generateActionableSuggestions(
        for trip: TripModel,
        understanding: ComprehensiveUnderstanding,
        context: ConversationContext
    ) -> [StructuredSuggestion]? {
        var suggestions: [StructuredSuggestion] = []
        
        // Generate suggestions based on trip details
        if trip.destinations?.isEmpty ?? true {
            suggestions.append(StructuredSuggestion(
                id: UUID().uuidString,
                type: "location",
                title: "Add Destinations",
                description: "Add destinations to your trip to get personalized suggestions",
                priority: "high",
                action: "add_destination",
                metadata: nil
            ))
        }
        
        if trip.itinerary?.isEmpty ?? true {
            suggestions.append(StructuredSuggestion(
                id: UUID().uuidString,
                type: "activity",
                title: "Create Itinerary",
                description: "Plan your daily activities for a well-organized trip",
                priority: "high",
                action: "create_itinerary",
                metadata: nil
            ))
        }
        
        // Budget suggestions
        if trip.budget == nil {
            suggestions.append(StructuredSuggestion(
                id: UUID().uuidString,
                type: "budget",
                title: "Set Budget",
                description: "Set a budget to track your spending",
                priority: "medium",
                action: "set_budget",
                metadata: nil
            ))
        }
        
        return suggestions.isEmpty ? nil : suggestions
    }
    
    private func generateBudgetSuggestions(
        for trip: TripModel,
        understanding: ComprehensiveUnderstanding
    ) -> [StructuredSuggestion]? {
        var suggestions: [StructuredSuggestion] = []
        
        if let budget = trip.budget {
            let dailyBudget = budget / Double(trip.duration)
            suggestions.append(StructuredSuggestion(
                id: UUID().uuidString,
                type: "budget",
                title: "Daily Budget: \(formatCurrency(dailyBudget))",
                description: "Your daily budget allocation for \(trip.duration) days",
                priority: "medium",
                action: "view_budget",
                metadata: ["daily": "\(dailyBudget)", "total": "\(budget)"]
            ))
        }
        
        return suggestions.isEmpty ? nil : suggestions
    }
    
    private func generateDestinationSuggestions(
        for trip: TripModel,
        understanding: ComprehensiveUnderstanding,
        context: ConversationContext
    ) -> [StructuredSuggestion]? {
        var suggestions: [StructuredSuggestion] = []
        
        // Suggest adding mentioned locations
        if !context.mentionedLocations.isEmpty {
            for location in context.mentionedLocations.prefix(3) {
                suggestions.append(StructuredSuggestion(
                    id: UUID().uuidString,
                    type: "location",
                    title: "Add \(location)",
                    description: "Add \(location) as a destination to your trip",
                    priority: "medium",
                    action: "add_destination",
                    metadata: ["location": location]
                ))
            }
        }
        
        return suggestions.isEmpty ? nil : suggestions
    }
    
    private func loadMLModels() {
        // In production, you would load custom Core ML models here
        // Example:
        // guard let modelURL = Bundle.main.url(forResource: "TripPredictor", withExtension: "mlmodelc") else { return }
        // guard let model = try? MLModel(contentsOf: modelURL) else { return }
        // self.tripPredictor = model
    }
}

// MARK: - Data Models

// MARK: - Chat Message Model
struct ChatMessage {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct TripAnalysis {
    var detectedLanguage: String?
    var extractedLocations: [String] = []
    var extractedActivities: [String] = []
    var sentiment: Sentiment = .neutral
    var keywords: [String] = []
}

enum Sentiment {
    case positive
    case neutral
    case negative
}

struct AISuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Priority
    let action: String?
    
    enum SuggestionType {
        case location
        case budget
        case tip
        case activity
        case warning
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    var icon: String {
        switch type {
        case .location: return "mappin.circle.fill"
        case .budget: return "dollarsign.circle.fill"
        case .tip: return "lightbulb.fill"
        case .activity: return "star.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct ReceiptAnalysis {
    var amount: Double?
    var date: Date?
    var merchant: String?
    var items: [String] = []
}





