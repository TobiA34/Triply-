#!/bin/bash

# Fix all remaining file paths that are missing directory prefixes

PROJECT_FILE="Triply.xcodeproj/project.pbxproj"
BACKUP_FILE="${PROJECT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fixing all remaining file paths..."
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
echo ""

# Widgets files (Widgets group has path = Widgets)
WIDGETS_FILES=(
    "TripSelectionIntent.swift:Widgets/TripSelectionIntent.swift"
    "WidgetActions.swift:Widgets/WidgetActions.swift"
    "TriplyWidget.swift:Widgets/TriplyWidget.swift"
)

# Models files (Models group has path = Models)
MODELS_FILES=(
    "CustomTheme.swift:Models/CustomTheme.swift"
    "TripEnums.swift:Models/TripEnums.swift"
    "TripCollaborator.swift:Models/TripCollaborator.swift"
    "DocumentFolder.swift:Models/DocumentFolder.swift"
    "TripMemory.swift:Models/TripMemory.swift"
    "TripDocument.swift:Models/TripDocument.swift"
    "AIStructuredResponse.swift:Models/AIStructuredResponse.swift"
    "PackingItem.swift:Models/PackingItem.swift"
    "Expense.swift:Models/Expense.swift"
    "ItineraryItem.swift:Models/ItineraryItem.swift"
    "DestinationModel.swift:Models/DestinationModel.swift"
    "AppSettings.swift:Models/AppSettings.swift"
)

# Managers files (Managers group has path = Managers)
MANAGERS_FILES=(
    "CameraPermissionManager.swift:Managers/CameraPermissionManager.swift"
    "CurrencyConverter.swift:Managers/CurrencyConverter.swift"
    "TicketScannerManager.swift:Managers/TicketScannerManager.swift"
    "DatabaseManager.swift:Managers/DatabaseManager.swift"
    "WeatherManager.swift:Managers/WeatherManager.swift"
    "PermissionRequestManager.swift:Managers/PermissionRequestManager.swift"
    "ThemeManager.swift:Managers/ThemeManager.swift"
    "CalendarManager.swift:Managers/CalendarManager.swift"
    "LocationManager.swift:Managers/LocationManager.swift"
    "NotificationManager.swift:Managers/NotificationManager.swift"
    "PackingAssistant.swift:Managers/PackingAssistant.swift"
    "ReceiptOCRManager.swift:Managers/ReceiptOCRManager.swift"
    "TripSharingManager.swift:Managers/TripSharingManager.swift"
    "VoiceNotesManager.swift:Managers/VoiceNotesManager.swift"
    "StructuredDataManager.swift:Managers/StructuredDataManager.swift"
    "AITripPlanner.swift:Managers/AITripPlanner.swift"
    "ExportManager.swift:Managers/ExportManager.swift"
)

echo "Updating Widgets files..."
for entry in "${WIDGETS_FILES[@]}"; do
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

echo "Updating Managers files..."
for entry in "${MANAGERS_FILES[@]}"; do
    filename="${entry%%:*}"
    fullpath="${entry##*:}"
    sed -i '' "s|path = \"${filename}\";|path = \"${fullpath}\";|g" "$PROJECT_FILE"
    sed -i '' "s|path = ${filename};|path = \"${fullpath}\";|g" "$PROJECT_FILE"
done

echo ""
echo "✅ All remaining file paths updated!"
echo "📝 Backup saved at: $BACKUP_FILE"



