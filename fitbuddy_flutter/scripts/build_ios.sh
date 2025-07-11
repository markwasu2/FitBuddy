#!/bin/bash

# Peregrine iOS Build Script
echo "Building Peregrine for iOS..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build iOS app
flutter build ios --release

echo "iOS build completed!"
echo "App bundle location: build/ios/iphoneos/Runner.app" 