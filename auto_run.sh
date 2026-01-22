#!/bin/bash

# Auto-run script for Triply app
# Watches for file changes and automatically rebuilds and runs the app

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
SCHEME="Triply"
BUNDLE_ID="com.triply.app"
SIMULATOR_UDID="11F27E2E-5199-43B7-9C11-E9159F59B324"
SDK="iphonesimulator"
DERIVED_DATA="./DerivedData"

# Directories to watch (excluding build artifacts)
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

# File extensions to watch
WATCH_EXTENSIONS=("swift" "strings" "plist" "xcodeproj" "yml")

echo -e "${BLUE}🚀 Triply Auto-Run Script${NC}"
echo -e "${BLUE}========================${NC}"
echo ""
echo -e "Watching for changes in:"
for dir in "${WATCH_DIRS[@]}"; do
    echo -e "  ${GREEN}✓${NC} $dir"
done
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Function to build and run
build_and_run() {
    echo -e "\n${BLUE}📦 Building project...${NC}"
    
    # Build
    if xcodebuild -project "$PROJECT_PATH/Triply.xcodeproj" \
        -scheme "$SCHEME" \
        -sdk "$SDK" \
        -derivedDataPath "$PROJECT_PATH/$DERIVED_DATA" \
        build \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        > /tmp/triply_build.log 2>&1; then
        
        echo -e "${GREEN}✅ Build succeeded${NC}"
        
        # Install
        echo -e "${BLUE}📱 Installing app...${NC}"
        xcrun simctl install "$SIMULATOR_UDID" \
            "$PROJECT_PATH/$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Triply.app" \
            > /dev/null 2>&1
        
        # Launch
        echo -e "${BLUE}🚀 Launching app...${NC}"
        xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID" > /dev/null 2>&1
        
        echo -e "${GREEN}✅ App running!${NC}\n"
    else
        echo -e "${RED}❌ Build failed${NC}"
        echo -e "${YELLOW}Last 10 lines of build log:${NC}"
        tail -10 /tmp/triply_build.log
        echo ""
    fi
}

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    echo -e "${RED}❌ fswatch is not installed${NC}"
    echo -e "${YELLOW}Installing fswatch...${NC}"
    
    if command -v brew &> /dev/null; then
        brew install fswatch
    else
        echo -e "${RED}Please install Homebrew first:${NC}"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "Then run: brew install fswatch"
        exit 1
    fi
fi

# Change to project directory
cd "$PROJECT_PATH"

# Initial build and run
build_and_run

# Watch for changes
echo -e "${BLUE}👀 Watching for file changes...${NC}\n"

# Build watch pattern
WATCH_PATTERN=""
for dir in "${WATCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        WATCH_PATTERN="$WATCH_PATTERN $dir"
    fi
done

# Also watch project.yml and project files
WATCH_PATTERN="$WATCH_PATTERN project.yml Triply.xcodeproj"

# Watch for changes
fswatch -o $WATCH_PATTERN | while read f; do
    # Filter by extension
    FILE_EXT="${f##*.}"
    SHOULD_BUILD=false
    
    for ext in "${WATCH_EXTENSIONS[@]}"; do
        if [ "$FILE_EXT" = "$ext" ] || [ -d "$f" ]; then
            SHOULD_BUILD=true
            break
        fi
    done
    
    if [ "$SHOULD_BUILD" = true ] || [ -z "$FILE_EXT" ]; then
        echo -e "${YELLOW}📝 Change detected: $f${NC}"
        sleep 1  # Debounce - wait 1 second for multiple rapid changes
        build_and_run
    fi
done


