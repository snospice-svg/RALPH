#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import os

# Create directory if it doesn't exist
icon_dir = "/Users/brettgoodson/RALPH/RALPH/Assets.xcassets/AppIcon.appiconset/"

# Icon sizes for iOS
sizes = [
    (40, "20x20@2x"),
    (60, "20x20@3x"),
    (58, "29x29@2x"),
    (87, "29x29@3x"),
    (80, "40x40@2x"),
    (120, "40x40@3x"),
    (120, "60x60@2x"),
    (180, "60x60@3x"),
    (20, "20x20@1x"),
    (40, "20x20@2x"),
    (29, "29x29@1x"),
    (58, "29x29@2x"),
    (40, "40x40@1x"),
    (80, "40x40@2x"),
    (152, "76x76@2x"),
    (167, "83.5x83.5@2x"),
    (1024, "1024x1024@1x")
]

def create_ralph_icon(size):
    # Create a square image with rounded corners effect
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background gradient effect - use blue
    bg_color = (52, 120, 246)  # iOS blue

    # Draw rounded rectangle background
    corner_radius = size // 8
    draw.rounded_rectangle(
        [(0, 0), (size-1, size-1)],
        radius=corner_radius,
        fill=bg_color
    )

    # Draw "R" letter in the center
    try:
        # Try to use system font
        font_size = int(size * 0.6)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()

    # Draw the "R" character
    text = "R"

    # Get text dimensions
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]  # Adjust for baseline

    # Draw white text
    draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

    # Add a small utensil icon if size is large enough
    if size >= 60:
        # Draw a simple fork/knife icon in the bottom right
        icon_size = size // 6
        icon_x = size - icon_size - (size // 12)
        icon_y = size - icon_size - (size // 12)

        # Draw simple fork lines
        line_width = max(1, size // 40)
        for i in range(3):
            fork_x = icon_x + (icon_size // 4) * i
            draw.line(
                [(fork_x, icon_y), (fork_x, icon_y + icon_size // 2)],
                fill=(255, 255, 255, 180),
                width=line_width
            )

    return img

# Generate all icon sizes
for size, name in sizes:
    icon = create_ralph_icon(size)
    filename = f"icon_{name}.png"
    filepath = os.path.join(icon_dir, filename)
    icon.save(filepath, "PNG")
    print(f"Generated {filename}")

print("All icons generated successfully!")