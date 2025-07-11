# Peregrine Flutter Migration Guide

This guide will help you migrate your iOS Peregrine app to Flutter for cross-platform (iOS + Android) development.

## Overview

Peregrine is a comprehensive fitness app with AI coaching, nutrition tracking, and workout planning. This Flutter version provides the same functionality across iOS and Android platforms.

## Features

- 🤖 AI-Powered Workout Plans
- 📊 Nutrition Tracking with Food Recognition
- 🏃‍♂️ Health Data Integration
- 📱 Cross-Platform Support
- 🎯 Personalized Goals & Progress Tracking

## Project Structure

```
peregrine_flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   └── services/                 # Business logic
├── assets/                       # Images, icons, fonts
├── android/                      # Android-specific config
├── ios/                         # iOS-specific config
└── test/                        # Unit and widget tests
```

## Getting Started

1. Create Flutter project: `flutter create peregrine_flutter`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Development

- **Hot Reload**: `r` in terminal
- **Hot Restart**: `R` in terminal
- **Quit**: `q` in terminal

## Building for Production

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

## Testing

```bash
flutter test
flutter analyze
```

## Deployment

See `DEPLOYMENT.md` for detailed deployment instructions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License. 