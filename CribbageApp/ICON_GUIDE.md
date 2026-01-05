# Quick App Icon Creation Guide

## Option 1: Using Mac Preview (Easiest)

1. **Open Preview** (built-in Mac app)
2. **File → New from Clipboard** (or create new)
3. **Tools → Adjust Size...**
   - Width: 1024
   - Height: 1024
   - Resolution: 72 pixels/inch
   - Click OK
4. **Use Tools → Annotate** to add:
   - Background color (green for card table)
   - Text (card suits: ♠ ♥ ♣ ♦)
   - Or paste/draw simple card imagery
5. **File → Export as PNG**
   - Name: `CribbageIcon.png`
   - Format: PNG

## Option 2: Use Online Generator (5 minutes)

### Recommended Sites:
- **AppIcon.co** - https://appicon.co
  - Upload any image
  - Generates all iOS sizes automatically
  - Download and extract
  
- **MakeAppIcon** - https://makeappicon.com
  - Upload 1024x1024 image
  - Creates full asset catalog
  
- **Canva** - https://canva.com
  - Search "iOS app icon"
  - Use templates
  - Customize with card suits
  - Download as PNG

## Option 3: Simple Design Ideas

### Design 1: Card Suits Grid
```
    ♠     ♥
    
    ♣     ♦
  CRIBBAGE
```
- Green background (#2E7D32)
- White spades and clubs
- Red hearts and diamonds

### Design 2: Single Large Card
```
  ┌─────────┐
  │  ♠ A    │
  │         │
  │    ♠    │
  │         │
  │    A ♠  │
  └─────────┘
```

### Design 3: Cribbage Board
```
  ●●●●●●●●●●
  ○○○○○○○○○○
    CRIBBAGE
```

## After Creating the Icon

1. **Add to Xcode:**
   - Open `CribbageApp.xcodeproj` in Xcode
   - In the navigator, click on `Assets.xcassets`
   - Click on `AppIcon`
   - Drag your 1024×1024 PNG file into the "1024pt" slot

2. **Verify:**
   - You should see your icon appear
   - Xcode will automatically scale it for all sizes

3. **Test:**
   - Build and run on simulator or device
   - Check that icon appears on home screen

## Color Suggestions

- **Green felt table**: #2E7D32, #1B5E20, #4CAF50
- **Playing card red**: #D32F2F, #C62828, #FF0000
- **Card white**: #FFFFFF, #FAFAFA
- **Gold/brass accents**: #FFC107, #FFB300

## Need Help?

If you want to use the Python generator (requires setup):
```bash
pip3 install Pillow
cd /Users/kellyford/Documents/GitHub/cribbage/CribbageApp
python3 generate_icon.py
```

This will create `CribbageIcon.png` ready to use!
