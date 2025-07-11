# Peregrine Deployment Guide

## Prerequisites

### iOS Deployment
- Xcode 15.0 or later
- Apple Developer Account
- iOS 13.0+ target
- Valid provisioning profiles and certificates

### Android Deployment
- Android Studio
- Google Play Console account
- Android SDK 21+ (API level 21)
- Keystore for app signing

## Build Commands

### Development Build
```bash
# Install dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run in debug mode
flutter run
```

### Production Build

#### iOS
```bash
# Build for iOS
./scripts/build_ios.sh

# Or manually:
flutter build ios --release
```

#### Android
```bash
# Build for Android
./scripts/build_android.sh

# Or manually:
flutter build apk --release
flutter build appbundle --release  # For Play Store
```

## App Store Deployment

### 1. Prepare App Store Connect
- Create new app in App Store Connect
- Set bundle identifier: `com.peregrine.app`
- Configure app information and metadata

### 2. Upload Build
```bash
# Archive the app
flutter build ios --release
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath build/ios
```

### 3. Submit for Review
- Upload build to App Store Connect
- Add screenshots and metadata
- Submit for review

## Google Play Store Deployment

### 1. Prepare Play Console
- Create new app in Google Play Console
- Set package name: `com.peregrine.app`
- Configure app information

### 2. Build and Upload
```bash
# Build app bundle
flutter build appbundle --release

# Upload to Play Console
# File location: build/app/outputs/bundle/release/app-release.aab
```

### 3. Release
- Upload AAB file to Play Console
- Add store listing assets
- Submit for review

## Environment Configuration

### Development
```bash
flutter run --flavor development
```

### Production
```bash
flutter run --flavor production
```

## Code Signing

### iOS
- Use automatic code signing in Xcode
- Or configure manual signing with certificates

### Android
- Generate keystore for app signing
- Configure signing in `android/app/build.gradle`

## Testing Before Deployment

### Local Testing
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for issues
flutter doctor
```

### Device Testing
- Test on physical iOS and Android devices
- Verify all features work correctly
- Test offline functionality

## Release Checklist

- [ ] All tests pass
- [ ] Code analysis clean
- [ ] App icons and launch screen configured
- [ ] Permissions properly configured
- [ ] Privacy policy updated
- [ ] App store metadata complete
- [ ] Screenshots for all device sizes
- [ ] Version number incremented
- [ ] Release notes prepared

## Troubleshooting

### Common Issues

1. **Build fails with signing errors**
   - Check certificates and provisioning profiles
   - Verify bundle identifier matches

2. **App crashes on launch**
   - Check permissions configuration
   - Verify all dependencies are included

3. **App rejected by stores**
   - Review app store guidelines
   - Check privacy policy compliance
   - Verify app functionality

### Support
For deployment issues, check:
- Flutter documentation
- Platform-specific guides
- App store review guidelines 