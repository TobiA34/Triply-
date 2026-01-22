//
//  AppGroupsDiagnosticView.swift
//  Itinero
//
//  Diagnostic tool to check App Groups configuration
//

import SwiftUI

struct AppGroupsDiagnosticView: View {
    @State private var diagnosticResults: [DiagnosticResult] = []
    
    struct DiagnosticResult: Identifiable {
        let id = UUID()
        let title: String
        let status: Status
        let message: String
        
        enum Status {
            case success
            case warning
            case error
            
            var icon: String {
                switch self {
                case .success: return "✅"
                case .warning: return "⚠️"
                case .error: return "❌"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("Run Diagnostics") {
                        runDiagnostics()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if !diagnosticResults.isEmpty {
                    Section("Diagnostic Results") {
                        ForEach(diagnosticResults) { result in
                            HStack {
                                Text(result.status.icon)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.headline)
                                        .foregroundColor(result.status.color)
                                    Text(result.message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("How to Fix") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("If App Groups is not configured:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Open Xcode")
                            Text("2. Select 'Itinero' target")
                            Text("3. Go to 'Signing & Capabilities'")
                            Text("4. Click '+ Capability'")
                            Text("5. Add 'App Groups'")
                            Text("6. Add identifier: group.com.nitinero.app")
                            Text("7. Repeat for 'ItineroWidgetExtensionExtension' target")
                            Text("8. Clean build folder (Shift+⌘+K)")
                            Text("9. Rebuild and reinstall app")
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("App Groups Diagnostic")
        }
    }
    
    private func runDiagnostics() {
        diagnosticResults = []
        
        let appGroupIdentifier = "group.com.nitinero.app"
        
        // Check 1: Can access App Group container
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            diagnosticResults.append(DiagnosticResult(
                title: "App Groups Access",
                status: .success,
                message: "App Group container accessible at: \(appGroupURL.path)"
            ))
            
            // Check 2: Database exists in App Group
            let dbURL = appGroupURL.appendingPathComponent("Itinero/default.store")
            if FileManager.default.fileExists(atPath: dbURL.path) {
                diagnosticResults.append(DiagnosticResult(
                    title: "Database Location",
                    status: .success,
                    message: "Database found in App Group container"
                ))
            } else {
                diagnosticResults.append(DiagnosticResult(
                    title: "Database Location",
                    status: .warning,
                    message: "Database not found in App Group. Run main app to migrate database."
                ))
            }
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "App Groups Access",
                status: .error,
                message: "App Groups NOT configured! containerURL returned nil. You must add App Groups capability in Xcode."
            ))
        }
        
        // Check 3: Entitlements file exists
        if let entitlementsPath = Bundle.main.path(forResource: "Itinero", ofType: "entitlements") {
            diagnosticResults.append(DiagnosticResult(
                title: "Entitlements File",
                status: .success,
                message: "Entitlements file found"
            ))
        } else {
            diagnosticResults.append(DiagnosticResult(
                title: "Entitlements File",
                status: .warning,
                message: "Entitlements file not found in bundle"
            ))
        }
        
        // Check 4: Application Support fallback
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let fallbackDB = appSupport.appendingPathComponent("Itinero/default.store")
            if FileManager.default.fileExists(atPath: fallbackDB.path) {
                diagnosticResults.append(DiagnosticResult(
                    title: "Fallback Database",
                    status: .warning,
                    message: "Database found in Application Support (old location). Should be migrated to App Group."
                ))
            }
        }
    }
}

#Preview {
    AppGroupsDiagnosticView()
}

