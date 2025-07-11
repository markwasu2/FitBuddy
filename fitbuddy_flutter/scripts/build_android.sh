#!/bin/bash

# Peregrine Android Build Script
echo "Building Peregrine for Android..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build Android app
flutter build apk --release

echo "Android build completed!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk" 