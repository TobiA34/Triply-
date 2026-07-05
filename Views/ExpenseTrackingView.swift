//
//  ExpenseTrackingView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseTrackingView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var ocrManager = ReceiptOCRManager()
    private let settingsManager = SettingsManager.shared
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    
    var totalExpenses: Double {
        trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
    }
    
    var expensesByCategory: [String: [Expense]] {
        Dictionary(grouping: trip.expenses ?? [], by: { $0.category })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                // AI Expense Insights
                AIExpenseInsightsCard(trip: trip)
                    .padding(.top)
                
                // Expense Chart
                ExpenseChartView(trip: trip)
                
                // Summary Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(settingsManager.formatAmount(totalExpenses))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        Spacer()
                        if let budget = trip.budget {
                            VStack(alignment: .trailing) {
                                Text("Remaining")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                let remaining = budget - totalExpenses
                                Text(settingsManager.formatAmount(remaining))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(remaining >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentPalette.accent.opacity(0.15), themeManager.currentPalette.accent.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.currentPalette.accent.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingAddExpense = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Expense")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentPalette.accent)
                        .cornerRadius(16)
                    }
                    
                    NavigationLink(destination: ExpenseInsightsView(trip: trip)) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Insights")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                
                // Expenses by Category
                if !expensesByCategory.isEmpty {
                    ForEach(Array(expensesByCategory.keys.sorted()), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(category)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(settingsManager.formatAmount(expensesByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            ForEach(expensesByCategory[category] ?? [], id: \.id) { expense in
                                ExpenseRowView(expense: expense, settingsManager: settingsManager)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        selectedExpense = expense
                                    }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeManager.currentPalette.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "receipt")
                                .font(.system(size: 36))
                                .foregroundColor(themeManager.currentPalette.accent)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Ready to track")
                                .font(.headline)
                                .foregroundColor(themeManager.currentPalette.text)
                            
                            Text("Your budget is perfectly balanced. Tap Add Expense to log your first cost.")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentPalette.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(trip: trip)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense)
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let settingsManager: SettingsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentPalette.text)
                HStack {
                    Text(expense.date, style: .date)
                        .font(.caption)
                    if !expense.category.isEmpty {
                        Text("•")
                            .font(.caption)
                        Text(expense.category)
                            .font(.caption)
                    }
                }
                .foregroundColor(themeManager.currentPalette.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(settingsManager.formatAmount(expense.amount))
                    .font(.headline)
                    .foregroundColor(.red)
                if expense.receiptImageData != nil {
                    Image(systemName: "doc.text.image")
                        .font(.caption)
                        .foregroundColor(themeManager.currentPalette.accent)
                }
            }
        }
        .padding()
        .background(themeManager.currentPalette.background)
        .cornerRadius(16)
        .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.currentPalette.accent.opacity(0.12), lineWidth: 1)
        )
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ocrManager = ReceiptOCRManager()
    private let settingsManager = SettingsManager.shared
    @State private var title = ""
    @State private var amount: String = ""
    @State private var category = "Other"
    @State private var expenseDate = Date()
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showingImagePicker = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let categories = ["Food", "Transport", "Accommodation", "Entertainment", "Shopping", "Other"]
    
    var isFormValid: Bool {
        validateForm().isValid
    }
    
    private func validateForm() -> ValidationResult {
        let titleResult = FormValidator.validateExpenseTitle(title)
        if !titleResult.isValid {
            return titleResult
        }
        
        let amountResult = FormValidator.validateExpenseAmount(amount)
        if !amountResult.isValid {
            return amountResult
        }
        
        let dateResult = FormValidator.validateExpenseDate(expenseDate)
        if !dateResult.isValid {
            return dateResult
        }
        
        let notesResult = FormValidator.validateNotes(notes)
        if !notesResult.isValid {
            return notesResult
        }
        
        return .valid
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Expense Title
                    ModernTextField(
                        title: "Expense Title",
                        text: $title,
                        icon: "tag.fill",
                        isRequired: true,
                        errorMessage: fieldErrors["title"]
                    )
                    .textInputAutocapitalization(.words)
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Amount")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("*")
                                .foregroundColor(.red)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        HStack(spacing: 12) {
                        Text(settingsManager.currentCurrency.symbol)
                                .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.secondary)
                                .frame(width: 30)
                            
                            TextField("0.00", text: $amount)
                                .font(.system(size: 20, weight: .semibold))
                            .keyboardType(.decimalPad)
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(fieldErrors["amount"] != nil ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                        
                        if let error = fieldErrors["amount"] {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Category
                    ModernPicker(
                        title: "Category",
                        selection: $category,
                        options: categories.map { (value: $0, label: $0) },
                        icon: "list.bullet",
                        isRequired: true
                    )
                    
                    // Date
                    ModernDatePicker(
                        title: "Date",
                        date: $expenseDate,
                        icon: "calendar",
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    // Receipt Section
                    VStack(alignment: .leading, spacing: 12) {
                        ModernSectionHeader(title: "Receipt", icon: "camera.fill")
                        
                    if let receiptImage = receiptImage {
                            VStack(spacing: 12) {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                                    .cornerRadius(12)
                        
                        if ocrManager.isProcessing {
                            HStack {
                                ProgressView()
                                        Text("Scanning receipt...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                        } else if !ocrManager.extractedText.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Extracted Text:")
                                            .font(.system(size: 13, weight: .semibold))
                                Text(ocrManager.extractedText)
                                            .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                            
                            if let extractedAmount = ocrManager.extractedAmount {
                                        Button {
                                            amount = String(format: "%.2f", extractedAmount)
                                        } label: {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                Text("Use Extracted Amount: \(settingsManager.formatAmount(extractedAmount))")
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                Button {
                            self.receiptImage = nil
                            ocrManager.extractedText = ""
                            ocrManager.extractedAmount = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove Receipt")
                        }
                                    .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    } else {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    Text("Scan Receipt")
                                }
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                    }
                    
                    // Notes
                    ModernTextEditor(
                        title: "Notes",
                        text: $notes,
                        icon: "note.text",
                        height: 100,
                        errorMessage: fieldErrors["notes"]
                    )
                    
                    // Save Button
                    ModernButton(
                        title: "Save Expense",
                        action: saveExpense,
                        icon: "checkmark.circle.fill",
                        isDisabled: !isFormValid
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        receiptImage = image
                        await ocrManager.processReceipt(image: image)
                    }
                }
            }
        }
    }
    
    @State private var fieldErrors: [String: String] = [:]
    
    private func saveExpense() {
        // Validate before saving
        let validation =  validateForm()
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Please check your expense details"
            showErrorAlert = true
            return
        }
        
        let amountValue = Double(amount) ?? 0
        let imageData = receiptImage?.jpegData(compressionQuality: 0.8)
        
        let expense = Expense(
            title: title,
            amount: amountValue,
            category: category,
            date: expenseDate,
            notes: notes,
            receiptImageData: imageData,
            currencyCode: settingsManager.currentCurrency.code
        )
        
        modelContext.insert(expense)
        
        if trip.expenses == nil {
            trip.expenses = []
        }
        trip.expenses?.append(expense)
        trip.lastModified = Date() // Trigger change detection efficiently
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save expense: \(error)")
            #endif
        }
    }
}

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) var dismiss
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(expense.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(settingsManager.formatAmount(expense.amount))
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    if !expense.category.isEmpty {
                        Label(expense.category, systemImage: "tag.fill")
                            .font(.headline)
                    }
                    
                    Text(expense.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !expense.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(expense.notes)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    if let imageData = expense.receiptImageData,
                       let image = UIImage(data: imageData) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Receipt")
                                .font(.headline)
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExpenseTrackingView(trip: TripModel(
        name: "Test Trip",
        startDate: Date(),
        endDate: Date()
    ))
    .modelContainer(for: [TripModel.self, Expense.self], inMemory: true)
}
