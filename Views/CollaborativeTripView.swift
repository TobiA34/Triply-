//
//  CollaborativeTripView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct CollaborativeTripView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripCollaborator.invitedAt, order: .reverse) private var allCollaborators: [TripCollaborator]
    @StateObject private var proLimiter = ProLimiter.shared
    
    @State private var showingInviteSheet = false
    @State private var newCollaboratorName = ""
    @State private var newCollaboratorEmail = ""
    @State private var selectedRole = "editor"
    @State private var showingShareLink = false
    @State private var shareLink = ""
    
    var tripCollaborators: [TripCollaborator] {
        allCollaborators.filter { $0.tripId == trip.id }
    }
    
    var body: some View {
        if !proLimiter.isPro {
            PaywallGateView(
                featureName: "Collaborative Planning",
                featureDescription: "Invite others to plan trips together and manage roles.",
                icon: "person.2.fill",
                iconColor: .blue
            )
            .navigationTitle("Collaborate")
        } else {
            collaborativeContent
        }
    }
    
    private var collaborativeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("collab.planning".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("collab.inviteDescription".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Share Link Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text("collab.shareLink".localized)
                            .font(.headline)
                        Spacer()
                    }
                    
                    HStack {
                        Text(shareLink.isEmpty ? "collab.generateLink".localized : shareLink)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button {
                            if shareLink.isEmpty {
                                generateShareLink()
                            } else {
                                copyShareLink()
                            }
                        } label: {
                            Image(systemName: shareLink.isEmpty ? "plus.circle.fill" : "doc.on.doc.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Collaborators List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("collab.collaborators".localized)
                            .font(.headline)
                        Spacer()
                        Button {
                            showingInviteSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("collab.invite".localized)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if tripCollaborators.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("collab.noCollaborators".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("collab.inviteFriends".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(tripCollaborators) { collaborator in
                            CollaboratorRow(collaborator: collaborator, trip: trip)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Features Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("collab.features".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    CollaborationFeatureCard(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "collab.voteOnActivities".localized,
                        description: "collab.voteOnActivitiesDesc".localized
                    )
                    
                    
                    CollaborationFeatureCard(
                        icon: "doc.text.fill",
                        iconColor: .blue,
                        title: "collab.sharedDocuments".localized,
                        description: "collab.sharedDocumentsDesc".localized
                    )
                    
                    CollaborationFeatureCard(
                        icon: "message.fill",
                        iconColor: .purple,
                        title: "collab.tripChat".localized,
                        description: "collab.communicateDesc".localized
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("collab.navTitle".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteSheet) {
            InviteCollaboratorSheet(
                trip: trip,
                onInvite: { name, email, role in
                    inviteCollaborator(name: name, email: email, role: role)
                }
            )
        }
        .onAppear {
            if shareLink.isEmpty {
                loadShareLink()
            }
        }
    }
    
    private func generateShareLink() {
        shareLink = "itinero://trip/\(trip.id.uuidString)"
        UserDefaults.standard.set(shareLink, forKey: "trip_share_\(trip.id.uuidString)")
    }
    
    private func loadShareLink() {
        if let saved = UserDefaults.standard.string(forKey: "trip_share_\(trip.id.uuidString)") {
            shareLink = saved
        }
    }
    
    private func copyShareLink() {
        UIPasteboard.general.string = shareLink
        HapticManager.shared.success()
    }
    
    private func inviteCollaborator(name: String, email: String, role: String) {
        let collaborator = TripCollaborator(
            tripId: trip.id,
            name: name,
            email: email.isEmpty ? nil : email,
            role: role
        )
        modelContext.insert(collaborator)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to invite collaborator: \(error)")
            HapticManager.shared.error()
        }
    }
}

struct CollaboratorRow: View {
    @Bindable var collaborator: TripCollaborator
    let trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(collaborator.name.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collaborator.name)
                    .font(.headline)
                
                if let email = collaborator.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: roleIcon)
                        .font(.caption2)
                    Text(collaborator.role.capitalized)
                        .font(.caption2)
                }
                .foregroundColor(roleColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(roleColor.opacity(0.1))
                .cornerRadius(4)
            }
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("collab.remove".localized, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("collab.removeCollaborator".localized, isPresented: $showingDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("collab.remove".localized, role: .destructive) {
                modelContext.delete(collaborator)
                try? modelContext.save()
            }
        } message: {
            Text("collab.removeConfirm".localized(collaborator.name))
        }
    }
    
    private var roleIcon: String {
        switch collaborator.role {
        case "owner": return "crown.fill"
        case "editor": return "pencil"
        default: return "eye"
        }
    }
    
    private var roleColor: Color {
        switch collaborator.role {
        case "owner": return .yellow
        case "editor": return .blue
        default: return .gray
        }
    }
}

struct InviteCollaboratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trip: TripModel
    let onInvite: (String, String, String) -> Void
    
    @State private var name = ""
    @State private var email = ""
    @State private var role = "editor"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("common.name".localized, text: $name)
                    TextField("collab.emailOptional".localized, text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("collab.details".localized)
                }
                
                Section {
                    Picker("collab.role".localized, selection: $role) {
                        Text("collab.viewer".localized).tag("viewer")
                        Text("collab.editor".localized).tag("editor")
                    }
                } header: {
                    Text("collab.role".localized)
                } footer: {
                    Text(role == "viewer" ? "collab.viewerDesc".localized : "collab.editorDesc".localized)
                }
            }
            .navigationTitle("collab.inviteCollaborator".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("collab.invite".localized) {
                        onInvite(name, email, role)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct CollaborationFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        CollaborativeTripView(trip: TripModel(
            name: "Paris Trip",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7)
        ))
    }
}

