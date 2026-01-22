#!/usr/bin/env swift

//
//  check_reference_files.swift
//  Checks and reports Xcode project file reference issues
//

import Foundation

let projectDir = "/Users/tobiadegoroye/Developer/SwiftUI/Triply"
let projectFile = "\(projectDir)/Triply.xcodeproj/project.pbxproj"

print("🔍 Checking Xcode project file references...")
print("")

guard let projectContent = try? String(contentsOfFile: projectFile, encoding: .utf8) else {
    print("❌ Could not read project file")
    exit(1)
}

// Extract file paths from project.pbxproj
let pathPattern = #"path = "([^"]+)""#
let regex = try! NSRegularExpression(pattern: pathPattern, options: [])
let matches = regex.matches(in: projectContent, options: [], range: NSRange(projectContent.startIndex..., in: projectContent))

var filePaths: Set<String> = []
for match in matches {
    if let range = Range(match.range(at: 1), in: projectContent) {
        let path = String(projectContent[range])
        if !path.isEmpty {
            filePaths.insert(path)
        }
    }
}

print("📋 Found \(filePaths.count) file references")
print("")

// Check if files exist
var missingFiles: [String] = []
var existingFiles: [String] = []

for filePath in filePaths.sorted() {
    // Skip special paths
    if filePath.contains(".xcassets") || filePath.contains(".entitlements") || filePath.contains(".storekit") {
        continue
    }
    
    let fullPath = "\(projectDir)/\(filePath)"
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: fullPath) {
        existingFiles.append(filePath)
    } else {
        missingFiles.append(filePath)
        print("❌ Missing: \(filePath)")
    }
}

print("")
print("📊 Summary:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Existing files: \(existingFiles.count)")
print("❌ Missing files: \(missingFiles.count)")
print("")

// Check for orphaned Swift files
print("🔎 Checking for files not in project...")

let directories = ["Views", "Managers", "Components", "Models", "Extensions"]
var orphanedFiles: [String] = []

for dir in directories {
    let dirPath = "\(projectDir)/\(dir)"
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dirPath) else { continue }
    
    for file in files where file.hasSuffix(".swift") {
        let relPath = "\(dir)/\(file)"
        let altPath = file // Sometimes just filename
        let basename = (file as NSString).deletingPathExtension
        
        // Check multiple patterns - project might reference by full path, relative path, or just filename
        let inProject = projectContent.contains("path = \"\(relPath)\"") || 
                       projectContent.contains("path = \"\(altPath)\"") ||
                       projectContent.contains("\(file)") ||
                       projectContent.contains("\(basename).swift") ||
                       projectContent.contains("/* \(file) */") ||
                       projectContent.contains("/* \(basename) */")
        
        if !inProject {
            orphanedFiles.append(relPath)
            print("⚠️  Not in project: \(relPath)")
        }
    }
}

print("")
print("📊 Complete Summary:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Valid references: \(existingFiles.count)")
print("❌ Missing files: \(missingFiles.count)")
print("⚠️  Orphaned files: \(orphanedFiles.count)")
print("")

if missingFiles.isEmpty && orphanedFiles.isEmpty {
    print("✅ All file references are valid!")
    exit(0)
}

if !missingFiles.isEmpty {
    print("❌ Issues found:")
    print("   Missing files need to be removed from project.pbxproj")
    print("   Or files need to be created/restored")
}

if !orphanedFiles.isEmpty {
    print("⚠️  Files not in project:")
    print("   These files exist but aren't referenced in project.pbxproj")
    print("   They should be added to the Xcode project")
}

print("")
print("💡 To fix:")
print("   1. Run: ./fix_reference_files.sh")
print("   2. Or manually edit project.pbxproj")
print("   3. Or use Xcode: File → Add Files to Project")

exit(missingFiles.isEmpty && orphanedFiles.isEmpty ? 0 : 1)

