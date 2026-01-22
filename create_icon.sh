#!/bin/bash

# Create a simple app icon using sips (built into macOS)
# This creates a 1024x1024 icon with "Triply" text

ICON_DIR="Assets.xcassets/AppIcon.appiconset"
ICON_FILE="$ICON_DIR/Icon-1024.png"

# Create a simple colored square as base
# Using sips to create a solid color image
echo "Creating app icon..."

# Create a temporary image with a gradient-like effect
# We'll use Python if available, otherwise create a simple solid color

if command -v python3 &> /dev/null; then
    python3 << EOF
from PIL import Image, ImageDraw, ImageFont
import os

# Create 1024x1024 image
size = 1024
img = Image.new('RGB', (size, size), color='#007AFF')
draw = ImageDraw.Draw(img)

# Draw a simple design
# Draw a circle in the center (outer circle)
center = size // 2
radius = size // 3
draw.ellipse([center - radius, center - radius, center + radius, center + radius], 
             fill='#FFFFFF', outline='#FFFFFF', width=20)

# Draw a globe inside the circle
globe_radius = int(radius * 0.75)  # Globe is 75% of circle size
globe_center_x = center
globe_center_y = center

# Draw the globe circle (filled with light blue)
draw.ellipse([globe_center_x - globe_radius, globe_center_y - globe_radius, 
              globe_center_x + globe_radius, globe_center_y + globe_radius],
             fill='#E3F2FD', outline='#007AFF', width=8)

# Draw latitude lines (horizontal arcs on the globe)
import math
for i in range(-2, 3):
    if i == 0:
        continue  # Skip equator, we'll draw it separately
    y_offset = int(globe_radius * i * 0.4)
    lat_radius = int((globe_radius**2 - y_offset**2)**0.5)
    if lat_radius > 0:
        # Draw latitude line as an arc (visible part of the globe)
        draw.arc([globe_center_x - lat_radius, globe_center_y - globe_radius + y_offset,
                  globe_center_x + lat_radius, globe_center_y + globe_radius + y_offset],
                 start=0, end=180, fill='#007AFF', width=4)

# Draw longitude lines (vertical arcs through the globe)
for i in range(4):
    angle = i * 90
    # Draw longitude line as a vertical arc
    x1 = globe_center_x - globe_radius
    y1 = globe_center_y - globe_radius
    x2 = globe_center_x + globe_radius
    y2 = globe_center_y + globe_radius
    # Draw the visible arc (front half of globe)
    draw.arc([x1, y1, x2, y2], start=angle-90, end=angle+90, fill='#007AFF', width=4)

# Draw equator (horizontal line through center - most prominent)
draw.line([globe_center_x - globe_radius, globe_center_y, 
           globe_center_x + globe_radius, globe_center_y],
          fill='#007AFF', width=6)

# Draw prime meridian (vertical line through center - most prominent)
draw.line([globe_center_x, globe_center_y - globe_radius,
           globe_center_x, globe_center_y + globe_radius],
          fill='#007AFF', width=6)

# Save the image
os.makedirs('$ICON_DIR', exist_ok=True)
img.save('$ICON_FILE', 'PNG')
print("✅ Icon created at $ICON_FILE")
EOF
else
    # Fallback: Use sips to create a simple solid color image
    # Create a 1x1 image and scale it up
    echo "Python/PIL not available. Creating simple icon with sips..."
    
    # Create directory if it doesn't exist
    mkdir -p "$ICON_DIR"
    
    # Create a simple blue square
    # Note: sips can't create images from scratch, so we'll need to use a different approach
    # For now, we'll create instructions
    echo "⚠️  Please add an icon manually:"
    echo "1. Open Xcode"
    echo "2. Go to Assets.xcassets > AppIcon"
    echo "3. Drag a 1024x1024 PNG image into the AppIcon set"
    echo ""
    echo "Or create Icon-1024.png (1024x1024) and place it in: $ICON_DIR"
fi


