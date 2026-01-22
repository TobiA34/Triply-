#!/bin/bash
# Fix schemes visibility

echo "Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo ""
echo "Schemes are now fixed. Reopen Xcode:"
echo "  open Triply.xcodeproj"
echo ""
echo "After Xcode opens, the schemes should appear in the dropdown."
