//
//  ExpenseSplittingView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct ExpenseSplittingView: View {
    @Bindable var expense: Expense
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var splitMethod: SplitMethod = .equal
    @State private var participants: [ExpenseParticipant] = []
    @State private var showingAddParticipant = false
    @State private var showingPaywall = false
    @State private var newParticipantName = ""
    
    enum SplitMethod: String, CaseIterable {
        case equal = "Equal"
        case percentage = "Percentage"
        case amount = "Custom Amount"
        
        var description: String {
            switch self {
            case .equal: return "Split equally among all participants"
            case .percentage: return "Split by percentage of total"
            case .amount: return "Enter custom amounts for each person"
            }
        }
    }
    
    var totalSplit: Double {
        participants.reduce(0) { $0 + $1.amount }
    }
    
    var isSplitValid: Bool {
        !participants.isEmpty && abs(totalSplit - expense.amount) < 0.01
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Pro Feature Gate
                if !proLimiter.isPro {
                    Section {
                        ExpenseSplitProFeatureBanner(
                            title: "Smart Expense Splitting",
                            description: "Split expenses fairly among travel companions with multiple split methods.",
                            icon: "person.2.fill",
                            iconColor: .green
                        ) {
                            showingPaywall = true
                        }
                    }
                }
                
                // Expense Info
                Section {
                    HStack {
                        Text("Total Amount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(expense.amount, specifier: "%.2f")")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Split Amount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(totalSplit, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(isSplitValid ? .green : .red)
                    }
                    
                    if !isSplitValid && totalSplit > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Difference: $\(abs(expense.amount - totalSplit), specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Expense Details")
                }
                
                // Split Method
                if proLimiter.isPro {
                    Section {
                        Picker("Split Method", selection: $splitMethod) {
                            ForEach(SplitMethod.allCases, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                    } header: {
                        Text("Split Method")
                    } footer: {
                        Text(splitMethod.description)
                    }
                    .onChange(of: splitMethod) { _, _ in
                        recalculateSplit()
                    }
                    
                    // Participants
                    Section {
                        if participants.isEmpty {
                            Button {
                                showingAddParticipant = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Participant")
                                }
                            }
                        } else {
                            ForEach(participants) { participant in
                                ParticipantRow(
                                    participant: participant,
                                    expenseAmount: expense.amount,
                                    splitMethod: splitMethod,
                                    totalParticipants: participants.count,
                                    onAmountChange: { newAmount in
                                        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
                                            participants[index].amount = newAmount
                                        }
                                    },
                                    onDelete: {
                                        participants.removeAll { $0.id == participant.id }
                                        recalculateSplit()
                                    }
                                )
                            }
                            
                            Button {
                                showingAddParticipant = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Participant")
                                }
                            }
                        }
                    } header: {
                        Text("Participants")
                    } footer: {
                        if participants.isEmpty {
                            Text("Add people to split this expense with")
                        } else {
                            Text("\(participants.count) participant\(participants.count == 1 ? "" : "s")")
                        }
                    }
                    
                    // Summary
                    if !participants.isEmpty && isSplitValid {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Split Summary")
                                    .font(.headline)
                                
                                ForEach(participants) { participant in
                                    HStack {
                                        Text(participant.name)
                                        Spacer()
                                        Text("$\(participant.amount, specifier: "%.2f")")
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("$\(totalSplit, specifier: "%.2f")")
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Split Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Split") {
                        saveSplit()
                    }
                    .disabled(!proLimiter.isPro || !isSplitValid)
                }
            }
            .sheet(isPresented: $showingAddParticipant) {
                AddParticipantView(name: $newParticipantName) {
                    let participant = ExpenseParticipant(
                        name: newParticipantName,
                        amount: 0
                    )
                    participants.append(participant)
                    newParticipantName = ""
                    recalculateSplit()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                NavigationStack {
                    PaywallView()
                }
            }
            .onAppear {
                loadExistingSplit()
            }
        }
    }
    
    private func recalculateSplit() {
        guard !participants.isEmpty else { return }
        
        switch splitMethod {
        case .equal:
            let amountPerPerson = expense.amount / Double(participants.count)
            for index in participants.indices {
                participants[index].amount = amountPerPerson
            }
            
        case .percentage:
            // Keep percentages, recalculate amounts
            let totalPercentage = participants.reduce(0) { $0 + $1.percentage }
            if totalPercentage > 0 {
                for index in participants.indices {
                    participants[index].amount = expense.amount * (participants[index].percentage / totalPercentage)
                }
            }
            
        case .amount:
            // User enters custom amounts, no auto-calculation
            break
        }
    }
    
    private func loadExistingSplit() {
        // Load existing split data if available
        // This would come from the Expense model
    }
    
    private func saveSplit() {
        // Save split information to expense
        // This would update the Expense model with split data
    }
}

struct ExpenseParticipant: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var percentage: Double = 0
    
    init(name: String, amount: Double, percentage: Double = 0) {
        self.name = name
        self.amount = amount
        self.percentage = percentage
    }
}

struct ParticipantRow: View {
    let participant: ExpenseParticipant
    let expenseAmount: Double
    let splitMethod: ExpenseSplittingView.SplitMethod
    let totalParticipants: Int
    let onAmountChange: (Double) -> Void
    let onDelete: () -> Void
    
    @State private var amountText: String = ""
    @State private var percentageText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(String(participant.name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Text(participant.name)
                    .font(.headline)
                
                Spacer()
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Amount Input based on split method
            switch splitMethod {
            case .equal:
                HStack {
                    Text("Amount:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(participant.amount, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
                
            case .percentage:
                HStack {
                    TextField("Percentage", text: $percentageText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: percentageText) { _, newValue in
                            if let percentage = Double(newValue) {
                                let amount = expenseAmount * (percentage / 100)
                                onAmountChange(amount)
                            }
                        }
                    
                    Text("%")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(participant.amount, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
                
            case .amount:
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: amountText) { _, newValue in
                            if let amount = Double(newValue) {
                                onAmountChange(amount)
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            amountText = String(format: "%.2f", participant.amount)
            if expenseAmount > 0 {
                percentageText = String(format: "%.1f", (participant.amount / expenseAmount) * 100)
            }
        }
    }
}

struct AddParticipantView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    let onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Participant Name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Add Participant")
                }
            }
            .navigationTitle("New Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct ExpenseSplitProFeatureBanner: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                onUpgrade()
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    ExpenseSplittingView(expense: Expense(
        title: "Dinner",
        amount: 100.0,
        category: "Food",
        date: Date()
    ))
}







