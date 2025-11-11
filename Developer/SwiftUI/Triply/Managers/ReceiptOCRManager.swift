//
//  ReceiptOCRManager.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import UIKit
import Vision
import VisionKit

@MainActor
class ReceiptOCRManager: ObservableObject {
    @Published var isProcessing = false
    @Published var extractedText: String = ""
    @Published var extractedAmount: Double?
    
    func processReceipt(image: UIImage) async {
        isProcessing = true
        extractedText = ""
        extractedAmount = nil
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        // Use Vision framework for text recognition
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self?.isProcessing = false
                return
            }
            
            var fullText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                fullText += topCandidate.string + "\n"
            }
            
            Task { @MainActor in
                self?.extractedText = fullText
                self?.extractedAmount = self?.extractAmount(from: fullText)
                self?.isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("OCR Error: \(error)")
            isProcessing = false
        }
    }
    
    private func extractAmount(from text: String) -> Double? {
        // Look for currency patterns
        let patterns = [
            "\\$\\s*([\\d,]+(?:\\.[\\d]{2})?)",
            "([\\d,]+(?:\\.[\\d]{2})?)\\s*\\$",
            "Total[\\s:]*([\\d,]+(?:\\.[\\d]{2})?)",
            "Amount[\\s:]*([\\d,]+(?:\\.[\\d]{2})?)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let amountRange = Range(match.range(at: 1), in: text) {
                        let amountString = String(text[amountRange]).replacingOccurrences(of: ",", with: "")
                        if let amount = Double(amountString) {
                            return amount
                        }
                    }
                }
            }
        }
        
        return nil
    }
}



