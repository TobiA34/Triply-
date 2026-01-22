#!/bin/bash

# Simple Auto-run script for Triply app
# Uses polling instead of fswatch (no dependencies required)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_PATH="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
SCHEME="Triply"
BUNDLE_ID="com.triply.app"
SIMULATOR_UDID="11F27E2E-5199-43B7-9C11-E9159F59B324"
SDK="iphonesimulator"
DERIVED_DATA="./DerivedData"
CHECK_INTERVAL=2  # Check every 2 seconds

# Directories to watch
WATCH_DIRS=(
    "Views"
    "Models"
    "Managers"
    "Extensions"
    "Libraries"
    "Resources"
    "Intents"
    "Widgets"
)

echo -e "${BLUE}🚀 Triply Auto-Run Script (Simple)${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""
echo -e "Watching for changes every ${YELLOW}${CHECK_INTERVAL} seconds${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Function to get file checksums
get_checksum() {
    find "${WATCH_DIRS[@]}" -type f \( -name "*.swift" -o -name "*.strings" -o -name "*.plist" -o -name "*.yml" \) 2>/dev/null | \
    xargs md5 -q 2>/dev/null | md5 -q
}

# Function to build and run
build_and_run() {
    local timestamp=$(date +"%H:%M:%S")
    echo -e "\n[${timestamp}] ${BLUE}📦 Building...${NC}"
    
    if xcodebuild -project "$PROJECT_PATH/Triply.xcodeproj" \
        -scheme "$SCHEME" \
        -sdk "$SDK" \
        -derivedDataPath "$PROJECT_PATH/$DERIVED_DATA" \
        build \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        > /tmp/triply_build.log 2>&1; then
        
        echo -e "[${timestamp}] ${GREEN}✅ Build succeeded${NC}"
        
        echo -e "[${timestamp}] ${BLUE}📱 Installing...${NC}"
        xcrun simctl install "$SIMULATOR_UDID" \
            "$PROJECT_PATH/$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Triply.app" \
            > /dev/null 2>&1 || true
        
        echo -e "[${timestamp}] ${BLUE}🚀 Launching...${NC}"
        xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID" > /dev/null 2>&1 || true
        
        echo -e "[${timestamp}] ${GREEN}✅ App running!${NC}"
    else
        echo -e "[${timestamp}] ${RED}❌ Build failed${NC}"
        tail -5 /tmp/triply_build.log | grep -E "(error|warning):" | head -3
    fi
}

cd "$PROJECT_PATH"

# Initial build
build_and_run

# Get initial checksum
last_checksum=$(get_checksum)

echo -e "\n${BLUE}👀 Watching for changes...${NC}\n"

# Watch loop
while true; do
    sleep "$CHECK_INTERVAL"
    
    current_checksum=$(get_checksum)
    
    if [ "$current_checksum" != "$last_checksum" ]; then
        last_checksum="$current_checksum"
        build_and_run
    fi
done


