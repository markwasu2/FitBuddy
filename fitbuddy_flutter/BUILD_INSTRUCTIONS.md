# Peregrine Cross-Platform Build Instructions

This guide will help you build Peregrine for both iOS and Android platforms using Flutter.

## Prerequisites

- Flutter SDK (latest stable version)
- Xcode (for iOS builds)
- Android Studio (for Android builds)
- Git

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd peregrine_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Development

### Run on iOS Simulator
```bash
flutter run -d ios
```

### Run on Android Emulator
```bash
flutter run -d android
```

### Run on Connected Device
```bash
flutter devices
flutter run -d <device-id>
```

## Building for Production

### iOS Build
```bash
# Clean previous builds
flutter clean

# Build for iOS
flutter build ios --release

# Or use the build script
./scripts/build_ios.sh
```

### Android Build
```bash
# Clean previous builds
flutter clean

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Or use the build script
./scripts/build_android.sh
```

## Testing

### Run Tests
```bash
flutter test
```

### Analyze Code
```bash
flutter analyze
```

### Check for Issues
```bash
flutter doctor
```

## Deployment

### iOS App Store
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Configure signing and certificates
3. Archive the app
4. Upload to App Store Connect

### Android Play Store
1. Build app bundle: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Configure store listing
4. Submit for review

## Troubleshooting

### Common Issues

1. **Build fails with signing errors**
   - Check certificates and provisioning profiles
   - Verify bundle identifier matches

2. **App crashes on launch**
   - Check permissions configuration
   - Verify all dependencies are included

3. **Platform-specific issues**
   - Run `flutter doctor` to check setup
   - Update Flutter SDK if needed

## Support

For issues and questions:
- Check Flutter documentation
- Review platform-specific guides
- Check the deployment guide in `DEPLOYMENT.md` 