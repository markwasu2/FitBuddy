# FitBuddy Cross-Platform Build Instructions

This guide will help you build FitBuddy for both iOS and Android platforms using Flutter.

## Prerequisites

### 1. Install Flutter SDK
```bash
# Download Flutter from https://flutter.dev/docs/get-started/install/macos
# Extract to ~/development/flutter
# Add to PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Install Development Tools

#### For iOS Development:
- Install Xcode from Mac App Store
- Accept Xcode license: `sudo xcodebuild -license accept`
- Install iOS Simulator

#### For Android Development:
- Install Android Studio from https://developer.android.com/studio
- Install Android SDK through Android Studio
- Set up Android Virtual Device (AVD)

### 3. Verify Installation
```bash
flutter doctor
```
All checks should pass (green checkmarks).

## Project Setup

### 1. Navigate to Flutter Project
```bash
cd fitbuddy_flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code (if using Hive)
```bash
flutter packages pub run build_runner build
```

## Building for iOS

### 1. iOS Simulator
```bash
# List available simulators
flutter devices

# Run on iOS Simulator
flutter run -d "iPhone 15 Pro"

# Or run on any available iOS device
flutter run -d ios
```

### 2. iOS Device
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select your team in Signing & Capabilities
# 2. Update Bundle Identifier if needed
# 3. Build and run
```

### 3. Build iOS App Bundle
```bash
# Debug build
flutter build ios

# Release build
flutter build ios --release

# Build for App Store
flutter build ios --release --no-codesign
```

## Building for Android

### 1. Android Emulator
```bash
# List available emulators
flutter devices

# Run on Android Emulator
flutter run -d "Android SDK built for x86"

# Or run on any available Android device
flutter run -d android
```

### 2. Android Device
```bash
# Enable USB debugging on your Android device
# Connect device via USB
# Run the app
flutter run -d android
```

### 3. Build Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs for different architectures
flutter build apk --split-per-abi --release
```

### 4. Build Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Platform-Specific Configuration

### iOS Configuration
The iOS configuration is already set up in `ios/Runner/Info.plist` with:
- HealthKit permissions
- Camera permissions
- Photo library permissions
- Microphone permissions

### Android Configuration
The Android configuration is already set up in `android/app/src/main/AndroidManifest.xml` with:
- Health Connect permissions
- Camera permissions
- Storage permissions
- Location permissions

## Testing

### 1. Unit Tests
```bash
flutter test
```

### 2. Integration Tests
```bash
flutter test integration_test/
```

### 3. Manual Testing
- Test on iOS Simulator
- Test on Android Emulator
- Test on physical devices

## Troubleshooting

### Common Issues

#### iOS Issues:
1. **Code signing errors**: Update team in Xcode project settings
2. **Permission denied**: Check Info.plist permissions
3. **Build fails**: Run `flutter clean` then `flutter pub get`

#### Android Issues:
1. **Gradle sync fails**: Update Android SDK and build tools
2. **Permission denied**: Check AndroidManifest.xml permissions
3. **Build fails**: Run `flutter clean` then `flutter pub get`

### Useful Commands
```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Check for issues
flutter doctor

# Update Flutter
flutter upgrade

# Check available devices
flutter devices
```

## Deployment

### iOS App Store
1. Build release version: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect

### Google Play Store
1. Build app bundle: `flutter build appbundle --release`
2. Upload to Google Play Console

## Environment Variables

Create a `.env` file in the project root for API keys:
```
GEMINI_API_KEY=your_gemini_api_key_here
```

## Next Steps

1. **Complete the remaining screens** (NutritionView, WorkoutView, etc.)
2. **Implement the AI service** for Gemini integration
3. **Add health data integration** for both platforms
4. **Test each feature** as you develop
5. **Optimize performance** for both platforms

## Support

If you encounter issues:
1. Check Flutter documentation: https://flutter.dev/docs
2. Check plugin documentation for specific features
3. Run `flutter doctor` to identify setup issues 