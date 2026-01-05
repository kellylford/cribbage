# TestFlight Preparation Checklist

## ✅ Completed

- [x] Created Assets.xcassets folder with AppIcon structure
- [x] Updated bundle identifier to `com.kellyford.cribbage`
- [x] Version set to 1.0
- [x] Build number set to 1
- [x] Display name set to "Cribbage"
- [x] App category set to "Card Games"
- [x] iOS deployment target set to 16.0
- [x] Development team configured (P887QF74N8)
- [x] Supports iPhone and iPad
- [x] Supports multiple orientations
- [x] VoiceOver accessibility features implemented

## 📋 Still Needed

### 1. App Icon
- [ ] Create a 1024×1024px app icon image
- [ ] Add the icon to `Assets.xcassets/AppIcon.appiconset/`
- [ ] Name it appropriately (e.g., `icon-1024.png`)
- [ ] Update the Contents.json to reference the icon file

**Icon Requirements:**
- Size: 1024×1024 pixels
- Format: PNG (no transparency)
- Color space: sRGB or P3
- Design should be simple, recognizable at small sizes
- Suggested: Playing card imagery or cribbage board elements

### 2. Privacy Policy (Optional for TestFlight, Required for App Store)
- [ ] Create privacy policy if you plan to collect any data
- [ ] Host it on a publicly accessible URL

### 3. TestFlight Beta Information
- [ ] Prepare a brief description of what testers should test
- [ ] Include any known issues or limitations
- [ ] Provide instructions for how to play if needed

### 4. Before Archiving
- [ ] Test the app on a physical device
- [ ] Verify VoiceOver works correctly with the new layout
- [ ] Check that all game features work as expected
- [ ] Ensure no crashes or errors

## 📝 Submission Steps

### Step 1: Create App Icon
You can create a simple icon using:
- **Preview** (Mac built-in): Create a colored square with card suits
- **Canva** (free online): Use templates
- **Icon generator tools**: Search for "iOS app icon generator"

### Step 2: Add Icon to Project
1. Save your 1024×1024px icon as PNG
2. Drag it into `CribbageApp/Assets.xcassets/AppIcon.appiconset/` in Xcode
3. Select the icon in the AppIcon settings and assign it

### Step 3: Archive the App
1. Open `CribbageApp.xcodeproj` in Xcode
2. Select "Any iOS Device" as the build destination
3. Go to Product → Archive
4. Wait for the archive to complete (2-5 minutes)

### Step 4: Upload to App Store Connect
1. In the Organizer window, select your archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Select "Upload"
5. Follow the prompts (accept defaults)
6. Wait for upload and processing (5-30 minutes)

### Step 5: Configure TestFlight
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Go to "My Apps" → "+ " → Create new app
   - **Platform**: iOS
   - **Name**: Cribbage
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.kellyford.cribbage
   - **SKU**: cribbage-2026 (or any unique identifier)
3. Go to TestFlight tab
4. Wait for build to appear (after processing)

### Step 6: Add Testers

**Internal Testing** (immediate, no review):
1. Go to TestFlight → Internal Testing
2. Add testers from your team (must be added in Users and Access first)
3. They can download immediately

**External Testing** (requires review):
1. Go to TestFlight → External Testing
2. Create a test group
3. Add tester emails
4. Submit for review (first time only, ~24-48 hours)
5. Testers receive email invitation after approval

## 🔑 Important Notes

- **Bundle ID**: `com.kellyford.cribbage` - This is unique to your app
- **Version**: 1.0 (increment for App Store releases)
- **Build Number**: 1 (increment for each TestFlight upload)
- **Team ID**: P887QF74N8 (already configured)

## 🆘 Troubleshooting

**"No signing identity found"**
- Ensure you're logged into Xcode with your Apple ID
- Go to Xcode → Settings → Accounts → Manage Certificates
- Create a certificate if needed

**"No provisioning profile found"**
- Xcode should create one automatically with "Automatic" signing
- Check that your Apple Developer Program membership is active

**"Missing compliance"**
- After upload, you'll be asked about encryption
- Select "No" if your app doesn't use encryption (it doesn't)

## 📊 Next Steps After TestFlight

Once testing is complete and you want to submit to the App Store:
- Add App Store screenshots (required)
- Write app description
- Set pricing (can be free)
- Complete App Store Information
- Submit for review
