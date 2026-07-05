//
//  Bundle+AppInfo.swift
//  Itinero
//
//  Marketing version + build for Settings / diagnostics.
//

import Foundation

extension Bundle {
    /// CFBundleShortVersionString (e.g. "2.0")
    var appMarketingVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    /// CFBundleVersion (build number)
    var appBuildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var appVersionDisplay: String {
        "\(appMarketingVersion) (\(appBuildNumber))"
    }
}
