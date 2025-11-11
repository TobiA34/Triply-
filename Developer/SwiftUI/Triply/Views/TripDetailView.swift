//
//  TripDetailView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTrip = false
    @State private var showingAddDestination = false
    @State private var showingShareSheet = false
    @State private var selectedTab = 0
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Trip Header (Always Visible)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trip.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        CategoryBadge(category: trip.category)
                    }
                    Spacer()
                    ShareButton(action: { showingShareSheet = true })
                }
                
                HStack {
                    Label(trip.formattedDateRange, systemImage: "calendar")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(trip.duration)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if let budget = trip.budget {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text("Budget: \(settingsManager.formatAmount(budget))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Tab Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TabButton(title: "Overview", icon: "list.bullet", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Itinerary", icon: "calendar", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    TabButton(title: "Expenses", icon: "creditcard", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    TabButton(title: "Weather", icon: "cloud.sun", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                    TabButton(title: "Packing", icon: "suitcase", isSelected: selectedTab == 4) {
                        selectedTab = 4
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Content based on tab
            TabView(selection: $selectedTab) {
                // Overview Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Destinations Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Destinations")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: { showingAddDestination = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            if trip.destinations?.isEmpty ?? true {
                                EmptyDestinationsView()
                            } else {
                                ForEach(trip.destinations?.sorted(by: { $0.order < $1.order }) ?? [], id: \.id) { destination in
                                    DestinationCardView(destination: destination, trip: trip, modelContext: modelContext)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Notes Section
                        if !trip.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                Text(trip.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .tag(0)
                
                // Itinerary Tab
                ItineraryView(trip: trip)
                    .tag(1)
                
                // Expenses Tab
                NavigationStack {
                    ExpenseTrackingView(trip: trip)
                }
                    .tag(2)
                
                // Weather Tab
                WeatherForecastView(trip: trip)
                    .tag(3)
                
                // Packing List Tab
                PackingListView(trip: trip)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditTrip = true }) {
                        Label("Edit Trip", systemImage: "pencil")
                    }
                    NavigationLink(destination: TripOptimizerView(trip: trip)) {
                        Label("Optimize Trip", systemImage: "sparkles")
                    }
                    NavigationLink(destination: TripRemindersView(trip: trip)) {
                        Label("Set Reminders", systemImage: "bell")
                    }
                    NavigationLink(destination: TripExportView(trip: trip)) {
                        Label("Export Trip", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditTrip) {
            EditTripView(trip: trip)
        }
        .sheet(isPresented: $showingAddDestination) {
            AddDestinationView(trip: trip)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [tripShareText()])
        }
        .onAppear {
            settingsManager.loadSettings(from: modelContext)
        }
    }
    
    private func tripShareText() -> String {
        var text = "\(trip.name)\n"
        text += "\(trip.formattedDateRange)\n"
        text += "Duration: \(trip.duration) days\n\n"
        if let destinations = trip.destinations, !destinations.isEmpty {
            text += "Destinations:\n"
            for dest in destinations.sorted(by: { $0.order < $1.order }) {
                text += "• \(dest.name)\n"
            }
        }
        if !trip.notes.isEmpty {
            text += "\nNotes: \(trip.notes)"
        }
        return text
    }
}

struct ShareButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundColor(.blue)
        }
    }
}

struct EmptyDestinationsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No destinations added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct DestinationCardView: View {
    @Bindable var destination: DestinationModel
    let trip: TripModel
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text(destination.name)
                    .font(.headline)
                Spacer()
                Button(action: {
                    trip.destinations?.removeAll { $0.id == destination.id }
                    trip.notes = trip.notes // Force change detection
                    try? modelContext.save()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            
            if !destination.address.isEmpty {
                Text(destination.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !destination.notes.isEmpty {
                Text(destination.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(20)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        TripDetailView(trip: TripModel(
            name: "Summer Europe Adventure",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            notes: "First time in Europe!"
        ))
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
    }
}
