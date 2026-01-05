#!/usr/bin/env python3
"""
Simple App Icon Generator for Cribbage App
Generates a 1024x1024px app icon with card suit symbols
Requires: PIL/Pillow library
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import sys
    
    # Create a 1024x1024 image
    size = 1024
    img = Image.new('RGB', (size, size), color='#2E7D32')  # Green like a card table
    draw = ImageDraw.Draw(img)
    
    # Add a border
    border_width = 20
    draw.rectangle(
        [(border_width, border_width), (size - border_width, size - border_width)],
        outline='#FFFFFF',
        width=border_width
    )
    
    # Try to use a system font, fallback to default
    try:
        # Try different font sizes
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 180)
        small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
        small_font = ImageFont.load_default()
    
    # Draw card suits in a 2x2 grid
    suits = ['♠', '♥', '♣', '♦']
    colors = ['#FFFFFF', '#FF0000', '#FFFFFF', '#FF0000']  # White for spades/clubs, red for hearts/diamonds
    
    positions = [
        (size * 0.25, size * 0.3),  # Top left
        (size * 0.75, size * 0.3),  # Top right
        (size * 0.25, size * 0.7),  # Bottom left
        (size * 0.75, size * 0.7),  # Bottom right
    ]
    
    for suit, color, pos in zip(suits, colors, positions):
        # Draw each suit symbol
        bbox = draw.textbbox((0, 0), suit, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_pos = (pos[0] - text_width/2, pos[1] - text_height/2)
        draw.text(text_pos, suit, fill=color, font=font)
    
    # Add "CRIBBAGE" text at bottom
    title = "CRIBBAGE"
    bbox = draw.textbbox((0, 0), title, font=small_font)
    title_width = bbox[2] - bbox[0]
    title_pos = ((size - title_width) / 2, size * 0.88)
    draw.text(title_pos, title, fill='#FFFFFF', font=small_font)
    
    # Save the image
    output_path = 'CribbageIcon.png'
    img.save(output_path, 'PNG')
    print(f"✅ App icon created successfully: {output_path}")
    print(f"📁 Next step: Drag this file into Assets.xcassets/AppIcon.appiconset/ in Xcode")
    
except ImportError:
    print("❌ PIL/Pillow library not found.")
    print("📦 Install it with: pip3 install Pillow")
    print("\nAlternatively, you can:")
    print("1. Use an online icon generator (search 'iOS app icon generator')")
    print("2. Create a 1024x1024px image in any graphics program")
    print("3. Use Canva or Figma with iOS app icon templates")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error creating icon: {e}")
    print("\nAlternative options:")
    print("1. Use an online icon generator")
    print("2. Create manually in Preview, Photoshop, or other image editor")
    print("   - Size: 1024x1024 pixels")
    print("   - Format: PNG (no transparency)")
    print("   - Suggested design: Card suits or cribbage board")
    sys.exit(1)
