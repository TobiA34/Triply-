//
//  ExpenseTrackingView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseTrackingView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ocrManager = ReceiptOCRManager()
    @StateObject private var settingsManager = SettingsManager.shared
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
                            Text("Total Expenses")
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
                            colors: [Color.red.opacity(0.1), Color.orange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
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
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                        Image(systemName: "creditcard")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No expenses yet")
                            .font(.headline)
                        Text("Tap 'Add Expense' to start tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
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
                .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(settingsManager.formatAmount(expense.amount))
                    .font(.headline)
                    .foregroundColor(.red)
                if expense.receiptImageData != nil {
                    Image(systemName: "doc.text.image")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ocrManager = ReceiptOCRManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var title = ""
    @State private var amount: String = ""
    @State private var category = "Other"
    @State private var expenseDate = Date()
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showingImagePicker = false
    
    private let categories = ["Food", "Transport", "Accommodation", "Entertainment", "Shopping", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    DatePicker("Date", selection: $expenseDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Receipt (Optional)") {
                    if let receiptImage = receiptImage {
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                        
                        if ocrManager.isProcessing {
                            HStack {
                                ProgressView()
                                Text("Scanning receipt...")
                                    .font(.caption)
                            }
                        } else if !ocrManager.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Extracted Text:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(ocrManager.extractedText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            if let extractedAmount = ocrManager.extractedAmount {
                                Button("Use Extracted Amount: \(settingsManager.formatAmount(extractedAmount))") {
                                    amount = String(Int(extractedAmount))
                                }
                                .font(.caption)
                            }
                        }
                        
                        Button("Remove Receipt") {
                            self.receiptImage = nil
                            ocrManager.extractedText = ""
                            ocrManager.extractedAmount = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Scan Receipt")
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                }
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
    
    private func saveExpense() {
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
        
        // Update a property to trigger SwiftData change detection
        trip.notes = trip.notes // Force change detection
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save expense: \(error)")
        }
    }
}

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    
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

