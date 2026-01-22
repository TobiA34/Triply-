#!/bin/bash

# fix_duplicate_paths.sh
# Wrapper script that calls the Python script to fix duplicate path issues
# When a group has a path property, its children should NOT include that path in their paths

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/fix_duplicate_paths.py"

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "❌ Error: Python script not found at $PYTHON_SCRIPT"
    exit 1
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is not installed"
    exit 1
fi

# Run the Python script
python3 "$PYTHON_SCRIPT"
