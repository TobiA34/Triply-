#!/bin/bash

# Script to create Xcode project for Triply app
# This script will create the Xcode project structure

set -e

PROJECT_NAME="Triply"
BUNDLE_ID="com.triply.app"
PROJECT_DIR="$(pwd)"

echo "Creating Xcode project for $PROJECT_NAME..."

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen is not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Please install Homebrew first, or install xcodegen manually:"
        echo "brew install xcodegen"
        exit 1
    fi
fi

# Generate Xcode project
if [ -f "project.yml" ]; then
    echo "Generating Xcode project from project.yml..."
    xcodegen generate
    echo "✅ Xcode project created successfully!"
    echo ""
    echo "To open the project, run:"
    echo "open $PROJECT_NAME.xcodeproj"
else
    echo "❌ project.yml not found!"
    exit 1
fi



