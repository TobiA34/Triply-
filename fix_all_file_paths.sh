#!/bin/bash

# Fix all file paths in project.pbxproj to include directory paths

PROJECT_FILE="Triply.xcodeproj/project.pbxproj"
BACKUP_FILE="${PROJECT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fixing all file paths in project.pbxproj..."
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
echo ""

# Files in Views/ directory
VIEWS_FILES=(
    "AIExpenseInsightsCard.swift:Views/AIExpenseInsightsCard.swift"
    "AIInsightsView.swift:Views/AIInsightsView.swift"
    "AddDestinationView.swift:Views/AddDestinationView.swift"
    "AddTripView.swift:Views/AddTripView.swift"
    "AnalyticsView.swift:Views/AnalyticsView.swift"
    "AnimatedBackgroundView.swift:Views/AnimatedBackgroundView.swift"
    "BudgetInsightsView.swift:Views/BudgetInsightsView.swift"
    "BudgetRow.swift:Views/BudgetRow.swift"
    "ContentView.swift:Views/ContentView.swift"
    "CreateFolderView.swift:Views/CreateFolderView.swift"
    "CurrencyConverterView.swift:Views/CurrencyConverterView.swift"
    "CurrencySelectionView.swift:Views/CurrencySelectionView.swift"
    "DestinationSearchView.swift:Views/DestinationSearchView.swift"
    "SocialMediaImportView.swift:Views/SocialMediaImportView.swift"
    "DocumentsView.swift:Views/DocumentsView.swift"
    "EditDocumentView.swift:Views/EditDocumentView.swift"
    "EditTripView.swift:Views/EditTripView.swift"
    "EnhancedTripCard.swift:Views/EnhancedTripCard.swift"
    "ExpenseChartView.swift:Views/ExpenseChartView.swift"
    "ExpenseInsightsView.swift:Views/ExpenseInsightsView.swift"
    "ExpenseTrackingView.swift:Views/ExpenseTrackingView.swift"
    "FloatingActionButton.swift:Views/FloatingActionButton.swift"
    "FolderDetailView.swift:Views/FolderDetailView.swift"
    "ItineraryView.swift:Views/ItineraryView.swift"
    "MoveToFolderView.swift:Views/MoveToFolderView.swift"
    "OnboardingView.swift:Views/OnboardingView.swift"
    "PackingListView.swift:Views/PackingListView.swift"
    "PaywallGateView.swift:Views/PaywallGateView.swift"
    "PaywallView.swift:Views/PaywallView.swift"
    "PermissionRequestView.swift:Views/PermissionRequestView.swift"
    "PlanGeneratorView.swift:Views/PlanGeneratorView.swift"
    "ProFeaturesView.swift:Views/ProFeaturesView.swift"
    "ScanningAnimationView.swift:Views/ScanningAnimationView.swift"
    "SettingsView.swift:Views/SettingsView.swift"
    "SmartPackingGeneratorView.swift:Views/SmartPackingGeneratorView.swift"
    "StatisticsView.swift:Views/StatisticsView.swift"
    "TagFlowLayout.swift:Views/TagFlowLayout.swift"
    "TripCalendarView.swift:Views/TripCalendarView.swift"
    "TripCalendarDisplayView.swift:Views/TripCalendarDisplayView.swift"
    "TripDetailView.swift:Views/TripDetailView.swift"
    "TripExportView.swift:Views/TripExportView.swift"
    "TripListView.swift:Views/TripListView.swift"
    "TripMapView.swift:Views/TripMapView.swift"
    "CountryPickerView.swift:Views/CountryPickerView.swift"
    "SmartTemplateLibraryView.swift:Views/SmartTemplateLibraryView.swift"
    "CoolAlertView.swift:Views/CoolAlertView.swift"
    "InlineContactFormView.swift:Views/InlineContactFormView.swift"
    "TripHeroImageView.swift:Views/TripHeroImageView.swift"
    "ImagePickerView.swift:Views/ImagePickerView.swift"
    "TripRemindersView.swift:Views/TripRemindersView.swift"
    "TripTemplates.swift:Views/TripTemplates.swift"
    "WeatherForecastView.swift:Views/WeatherForecastView.swift"
)

# Files in Extensions/ directory
EXTENSIONS_FILES=(
    "LocalizedString.swift:Extensions/LocalizedString.swift"
    "FormValidation.swift:Extensions/FormValidation.swift"
)

echo "Updating Views files..."
for entry in "${VIEWS_FILES[@]}"; do
    filename="${entry%%:*}"
    fullpath="${entry##*:}"
    
    # Update path = "filename" to path = "Views/filename"
    sed -i '' "s|path = \"${filename}\";|path = \"${fullpath}\";|g" "$PROJECT_FILE"
    sed -i '' "s|path = ${filename};|path = \"${fullpath}\";|g" "$PROJECT_FILE"
done

echo "Updating Extensions files..."
for entry in "${EXTENSIONS_FILES[@]}"; do
    filename="${entry%%:*}"
    fullpath="${entry##*:}"
    
    # Update path = "filename" to path = "Extensions/filename"
    sed -i '' "s|path = \"${filename}\";|path = \"${fullpath}\";|g" "$PROJECT_FILE"
    sed -i '' "s|path = ${filename};|path = \"${fullpath}\";|g" "$PROJECT_FILE"
done

echo ""
echo "✅ All file paths updated!"
echo "📝 Backup saved at: $BACKUP_FILE"



