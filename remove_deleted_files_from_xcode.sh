#!/bin/bash
# Script to remove deleted files from Xcode project
# Run this script to clean up the project file

echo "To fix the build errors, please do one of the following:"
echo ""
echo "OPTION 1 (Recommended - In Xcode):"
echo "1. Open Triply.xcodeproj in Xcode"
echo "2. In the Project Navigator, find these files (they will show in red):"
echo "   - VoiceNotesView.swift"
echo "   - TripOptimizerView.swift"
echo "   - ThemeSuggestionsView.swift"
echo "   - ThemeDefaultsView.swift"
echo "   - ThemeDebugView.swift"
echo "   - ThemeCreatorView.swift"
echo "   - EmergencyInfoView.swift"
echo "   - TimeZoneHelperView.swift"
echo "   - CollaborativeTripView.swift"
echo "   - BatchTicketScanView.swift"
echo "   - AITripAssistantView.swift"
echo "   - AIQuickActionsView.swift"
echo "   - AIChatView.swift"
echo "3. Right-click each file and select 'Delete' -> 'Remove Reference'"
echo "4. Clean build folder (Cmd+Shift+K) and rebuild"
echo ""
echo "OPTION 2 (Command line - if you have xcodeproj gem):"
echo "gem install xcodeproj"
echo "ruby -e \"require 'xcodeproj'; proj = Xcodeproj::Project.open('Triply.xcodeproj'); files = ['VoiceNotesView.swift', 'TripOptimizerView.swift', 'ThemeSuggestionsView.swift', 'ThemeDefaultsView.swift', 'ThemeDebugView.swift', 'ThemeCreatorView.swift', 'EmergencyInfoView.swift', 'TimeZoneHelperView.swift', 'CollaborativeTripView.swift', 'BatchTicketScanView.swift', 'AITripAssistantView.swift', 'AIQuickActionsView.swift', 'AIChatView.swift']; proj.files.each { |f| f.remove_from_project if files.include?(f.path) }; proj.save\""
echo ""
echo "The files have already been deleted from the filesystem."
echo "We just need to remove their references from the Xcode project file."




