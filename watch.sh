#!/bin/bash

# Watch script - automatically rebuilds when files change
# Great for development in Cursor!

set -e

PROJECT_NAME="Triply"
SCHEME="Triply"

echo "👀 Watching for file changes..."
echo "   Press Ctrl+C to stop"
echo ""

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    echo "⚠️  fswatch not found. Installing..."
    brew install fswatch
fi

# Watch Swift files
fswatch -o . --include='\.swift$' | while read f; do
    echo ""
    echo "🔄 File changed, rebuilding..."
    ./build.sh
done



