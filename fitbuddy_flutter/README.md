# FitBuddy Flutter Migration Guide

## Overview
This guide will help you migrate your iOS FitBuddy app to Flutter for cross-platform (iOS + Android) development.

## Prerequisites (Manual Steps Required)

### 1. Install Flutter SDK
```bash
# Download Flutter from https://flutter.dev/docs/get-started/install/macos
# Extract to ~/development/flutter
# Add to PATH: export PATH="$PATH:$HOME/development/flutter/bin"
```

### 2. Install Development Tools
- **Xcode** (for iOS development)
- **Android Studio** (for Android development)
- **VS Code** or **Android Studio** (for Flutter development)

### 3. Verify Installation
```bash
flutter doctor
```

## Migration Steps

### Phase 1: Project Setup
1. Create Flutter project: `flutter create fitbuddy_flutter`
2. Set up dependencies in `pubspec.yaml`
3. Configure platform-specific settings

### Phase 2: Core Features Migration
1. **Data Models** - Convert Swift structs to Dart classes
2. **State Management** - Implement Provider/Riverpod
3. **Navigation** - Convert to Flutter navigation
4. **UI Components** - Recreate in Flutter widgets

### Phase 3: Platform Integration
1. **Health Data** - Implement HealthKit (iOS) + Google Fit (Android)
2. **Camera** - Use camera plugin for nutrition tracking
3. **AI Integration** - Port Gemini API calls
4. **Local Storage** - Use SharedPreferences/Hive

### Phase 4: Testing & Deployment
1. Test on iOS simulator
2. Test on Android emulator
3. Build for both platforms

## Key Differences: Swift → Flutter

| Swift Feature | Flutter Equivalent |
|---------------|-------------------|
| SwiftUI Views | Flutter Widgets |
| @State/@ObservedObject | Provider/Riverpod |
| NavigationView | Navigator |
| Core Data | Hive/SQLite |
| HealthKit | health_kit plugin |
| UIKit | Material/Cupertino |

## Project Structure
```
fitbuddy_flutter/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── services/
│   ├── screens/
│   ├── widgets/
│   └── utils/
├── android/
├── ios/
└── pubspec.yaml
```

## Next Steps
1. Install Flutter SDK
2. Run `flutter doctor` to verify setup
3. Follow the migration guide step by step
4. Test each feature as you migrate 