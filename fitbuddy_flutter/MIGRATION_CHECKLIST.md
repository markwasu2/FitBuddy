# FitBuddy iOS to Flutter Migration Checklist

## Phase 1: Environment Setup (Manual Steps)

### ✅ 1. Install Flutter SDK
- [ ] Download Flutter from https://flutter.dev/docs/get-started/install/macos
- [ ] Extract to `~/development/flutter`
- [ ] Add to PATH: `export PATH="$PATH:$HOME/development/flutter/bin"`
- [ ] Add to `~/.zshrc` for permanent access

### ✅ 2. Install Development Tools
- [ ] Install Xcode from Mac App Store
- [ ] Accept Xcode license: `sudo xcodebuild -license accept`
- [ ] Install Android Studio from https://developer.android.com/studio
- [ ] Install Android SDK through Android Studio

### ✅ 3. Verify Installation
```bash
flutter doctor
```
- [ ] All checks should pass (green checkmarks)

## Phase 2: Project Setup

### ✅ 4. Create Flutter Project
```bash
cd ~/Desktop
flutter create fitbuddy_flutter
cd fitbuddy_flutter
```

### ✅ 5. Install Dependencies
```bash
flutter pub get
```

### ✅ 6. Generate Hive Models
```bash
flutter packages pub run build_runner build
```

## Phase 3: Core Features Migration

### ✅ 7. Data Models (Already Created)
- [x] User model (replaces Swift User struct)
- [x] FoodEntry model (replaces Swift FoodEntry struct)
- [ ] Workout model (needs to be created)
- [ ] Exercise model (needs to be created)

### ✅ 8. Services (Already Created)
- [x] StorageService (replaces Core Data)
- [ ] HealthService (needs to be created)
- [ ] AIService (needs to be created)

### ✅ 9. UI Screens (Need to be Created)
- [ ] DashboardView
- [ ] NutritionView
- [ ] WorkoutView
- [ ] AICoachView
- [ ] ProfileView
- [ ] OnboardingView

## Phase 4: Platform Integration

### ✅ 10. iOS Configuration
- [ ] Add HealthKit capability in Xcode
- [ ] Configure Info.plist permissions
- [ ] Set up camera permissions

### ✅ 11. Android Configuration
- [ ] Configure AndroidManifest.xml
- [ ] Add health permissions
- [ ] Set up camera permissions

## Phase 5: Testing & Deployment

### ✅ 12. Testing
- [ ] Test on iOS simulator
- [ ] Test on Android emulator
- [ ] Test on physical devices

### ✅ 13. Build & Deploy
- [ ] Build iOS app: `flutter build ios`
- [ ] Build Android app: `flutter build apk`

## Manual Steps Required

### Step 1: Install Flutter
1. Go to https://flutter.dev/docs/get-started/install/macos
2. Download the Flutter SDK
3. Extract to `~/development/flutter`
4. Open Terminal and run:
   ```bash
   echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Step 2: Install Xcode
1. Open Mac App Store
2. Search for "Xcode"
3. Install Xcode
4. Open Terminal and run:
   ```bash
   sudo xcodebuild -license accept
   ```

### Step 3: Install Android Studio
1. Go to https://developer.android.com/studio
2. Download and install Android Studio
3. Open Android Studio and install Android SDK

### Step 4: Verify Setup
```bash
flutter doctor
```

### Step 5: Create Project
```bash
cd ~/Desktop
flutter create fitbuddy_flutter
cd fitbuddy_flutter
```

### Step 6: Replace Files
1. Replace `pubspec.yaml` with the one provided
2. Replace `lib/main.dart` with the one provided
3. Add all the model and service files provided

### Step 7: Install Dependencies
```bash
flutter pub get
```

### Step 8: Generate Code
```bash
flutter packages pub run build_runner build
```

### Step 9: Run the App
```bash
flutter run
```

## Key Differences to Remember

| iOS/Swift | Flutter/Dart |
|-----------|--------------|
| SwiftUI Views | Flutter Widgets |
| @State/@ObservedObject | Provider/Riverpod |
| NavigationView | Navigator |
| Core Data | Hive/SQLite |
| HealthKit | health_kit plugin |
| UIKit | Material/Cupertino |

## Next Steps After Setup

1. **Create the remaining screens** (DashboardView, NutritionView, etc.)
2. **Implement the AI service** for Gemini integration
3. **Add health data integration** for both iOS and Android
4. **Test each feature** as you migrate
5. **Optimize performance** for both platforms

## Troubleshooting

- If `flutter doctor` shows issues, follow the instructions it provides
- If build fails, run `flutter clean` then `flutter pub get`
- For iOS issues, check Xcode project settings
- For Android issues, check Android Studio settings 