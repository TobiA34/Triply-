#!/bin/bash

# Fix Managers and Models file paths

PROJECT_FILE="Triply.xcodeproj/project.pbxproj"

echo "🔧 Fixing Managers and Models file paths..."

# Managers files
MANAGERS_FILES=(
    "HapticManager.swift:Managers/HapticManager.swift"
    "SocialMediaManager.swift:Managers/SocialMediaManager.swift"
    "TripOptimizer.swift:Managers/TripOptimizer.swift"
    "ProLimiter.swift:Managers/ProLimiter.swift"
    "SmartTemplateManager.swift:Managers/SmartTemplateManager.swift"
    "SettingsManager.swift:Managers/SettingsManager.swift"
    "TripDataManager.swift:Managers/TripDataManager.swift"
    "IAPManager.swift:Managers/IAPManager.swift"
    "AppleAIFoundation.swift:Managers/AppleAIFoundation.swift"
    "DestinationSearchManager.swift:Managers/DestinationSearchManager.swift"
    "WidgetDataSync.swift:Managers/WidgetDataSync.swift"
)

# Models files (Models group has path = Models)
MODELS_FILES=(
    "Country.swift:Models/Country.swift"
    "TripModel.swift:Models/TripModel.swift"
    "SmartTripTemplate.swift:Models/SmartTripTemplate.swift"
)

echo "Updating Managers files..."
for entry in "${MANAGERS_FILES[@]}"; do
    filename="${entry%%:*}"
    fullpath="${entry##*:}"
    
    sed -i '' "s|path = \"${filename}\";|path = \"${fullpath}\";|g" "$PROJECT_FILE"
    sed -i '' "s|path = ${filename};|path = \"${fullpath}\";|g" "$PROJECT_FILE"
done

echo "Updating Models files..."
for entry in "${MODELS_FILES[@]}"; do
    filename="${entry%%:*}"
    fullpath="${entry##*:}"
    
    sed -i '' "s|path = \"${filename}\";|path = \"${fullpath}\";|g" "$PROJECT_FILE"
    sed -i '' "s|path = ${filename};|path = \"${fullpath}\";|g" "$PROJECT_FILE"
done

echo "✅ Done!"



