#!/usr/bin/env python3
"""
Generate all required iOS app icon sizes from the 1024x1024 source icon
"""

try:
    from PIL import Image
    import os
    
    # Define all required icon sizes for iOS
    icon_sizes = [
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    
    # Path to source icon
    source_icon_path = "Assets.xcassets/AppIcon.appiconset/cribbage-1024.png"
    output_dir = "Assets.xcassets/AppIcon.appiconset"
    
    # Check if source exists
    if not os.path.exists(source_icon_path):
        print(f"❌ Source icon not found at {source_icon_path}")
        exit(1)
    
    # Open source image
    print(f"📖 Loading source icon: {source_icon_path}")
    source_img = Image.open(source_icon_path)
    
    # Generate all sizes
    print(f"\n🎨 Generating {len(icon_sizes)} icon sizes...")
    for filename, size in icon_sizes:
        output_path = os.path.join(output_dir, filename)
        
        # Resize image with high-quality resampling
        resized_img = source_img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save the resized image
        resized_img.save(output_path, 'PNG')
        print(f"  ✅ Created {filename} ({size}x{size}px)")
    
    print(f"\n✅ All icons generated successfully in {output_dir}")
    print("\n📝 Next steps:")
    print("1. Update Assets.xcassets/AppIcon.appiconset/Contents.json")
    print("2. Rebuild the archive")
    
except ImportError:
    print("❌ PIL/Pillow library not found.")
    print("📦 Install it with: pip3 install Pillow")
    exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
