# Localization Setup Instructions

## Files Created

The following files have been created for Chinese localization:

1. **LocalizationManager.swift** - `/UpUp/Shared/Utilities/LocalizationManager.swift`
2. **English Localizable.strings** - `/UpUp/Resources/en.lproj/Localizable.strings`
3. **Chinese Localizable.strings** - `/UpUp/Resources/zh-Hans.lproj/Localizable.strings`

## Steps to Complete Setup in Xcode

### 1. Add LocalizationManager.swift to Project (Already created, just verify)
   - The file is already created at: `UpUp/Shared/Utilities/LocalizationManager.swift`
   - If not in Xcode, drag it from Finder to the Xcode project navigator

### 2. Add Localization Files to Xcode Project

#### Option A: Add via Xcode (Recommended)
1. Open `UpUp.xcodeproj` in Xcode
2. In Project Navigator, right-click on the UpUp folder
3. Select "Add Files to UpUp..."
4. Navigate to `UpUp/Resources/` folder
5. Select both `en.lproj` and `zh-Hans.lproj` folders
6. Make sure "Create folder references" is selected (not "Create groups")
7. Click "Add"

#### Option B: Enable Localization in Project Settings
1. In Xcode, select the project file (UpUp) in the navigator
2. Select the UpUp target
3. Go to the "Info" tab
4. In "Localizations" section, click the "+" button
5. Add "Chinese (Simplified)" (zh-Hans)
6. This will prompt you to choose files to localize

### 3. Configure Info.plist for Localization
1. Open Info.plist in Xcode
2. Add a new key: `CFBundleDevelopmentRegion` with value `en`
3. Add a new key: `CFBundleLocalizations` (if not present)
4. Under `CFBundleLocalizations`, add two items:
   - Item 0: `en`
   - Item 1: `zh-Hans`

### 4. Build and Test
1. Build the project (⌘+B)
2. Run the app
3. Go to Settings page
4. Select language (System/English/简体中文)
5. Navigate through the app to see translations in action

## How It Works

- **System Language**: The app detects system language and defaults to Chinese if system is set to Chinese, otherwise English
- **Manual Selection**: Users can override the system language in Settings
- **Real-time Switching**: Language changes take effect immediately when selected

## Troubleshooting

If localization doesn't work:
1. Make sure both `.lproj` folders are visible in Xcode's Project Navigator
2. Verify that the `.strings` files appear as "Localizable.strings (English)" and "Localizable.strings (Chinese, Simplified)" in Xcode
3. Clean build folder (⌘+Shift+K) and rebuild
4. Check that `LocalizationManager.swift` is included in the target's "Compile Sources"

## Adding More Translations

To add more strings:
1. Add the key to both `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`
2. Use `"your.key".localized` in Swift code to access the translation
