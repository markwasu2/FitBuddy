# Peregrine - iOS Fitness App

A comprehensive iOS fitness app built with SwiftUI that helps users track workouts, plan routines, and achieve their fitness goals.

## Features

- **Onboarding**: Personalized setup with fitness goals and equipment preferences
- **AI-Powered Chatbot**: Get workout advice and plan routines using Google's Gemini AI
- **Workout Tracking**: Log and track your workouts with detailed exercise information
- **Health Integration**: Sync with Apple HealthKit for comprehensive health data
- **Calendar Integration**: Schedule workouts and get reminders
- **Voice Commands**: Use speech recognition for hands-free interaction
- **Photo Scanner**: Scan food items for calorie tracking (placeholder implementation)
- **Modern UI**: Beautiful, intuitive interface with modern design principles

## Recent Fixes Applied

### Security Improvements
- ✅ **Removed hardcoded API key** from source code
- ✅ **Added secure configuration system** using environment variables
- ✅ **Created Config.swift** for centralized configuration management

### Error Handling & Stability
- ✅ **Fixed fatalError calls** in Persistence.swift to prevent app crashes
- ✅ **Added proper error handling** for Core Data operations
- ✅ **Improved GPT service error handling** with graceful fallbacks
- ✅ **Fixed force unwrapping** in Core Data initialization

### Permissions & Configuration
- ✅ **Added missing permission descriptions** in Info.plist:
  - Microphone access for voice commands
  - Speech recognition for AI interaction
  - Photo library access for food scanning
- ✅ **Enhanced permission handling** for all system integrations

### Code Quality
- ✅ **Improved API key validation** with feature flags
- ✅ **Added graceful degradation** when AI features are unavailable
- ✅ **Enhanced error messages** for better user experience

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Peregrine
```

### 2. Configure API Key (Required for AI Features)

#### Option A: Environment Variable (Recommended for Production)
Set the `GEMINI_API_KEY` environment variable:
```bash
export GEMINI_API_KEY="your_actual_api_key_here"
```

#### Option B: Direct Configuration (Development Only)
Edit `Peregrine/Config.swift` and replace the placeholder:
```swift
// Replace this line in Config.swift
return "YOUR_GEMINI_API_KEY_HERE"
// With your actual API key
return "your_actual_api_key_here"
```

### 3. Get a Gemini API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the key and use it in the configuration above

### 4. Build and Run
```bash
# Open in Xcode
open Peregrine.xcodeproj

# Or build from command line
xcodebuild -project Peregrine.xcodeproj -scheme Peregrine -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

### Core Components
- **PeregrineApp**: Main app entry point with environment objects
- **GPTService**: AI integration with Google Gemini
- **HealthKitManager**: Health data integration
- **CalendarManager**: Event scheduling
- **WorkoutPlanManager**: Workout planning and management
- **NotificationManager**: Push notifications

### Key Files
- `fit_buddy_mvp.swift`: Main app logic and UI components
- `Config.swift`: Configuration and API key management
- `Persistence.swift`: Core Data setup and error handling
- `Info.plist`: App permissions and configuration

## Permissions Required

The app requests the following permissions:
- **Calendar**: Schedule workouts and reminders
- **Health**: Track fitness data and sync with Apple Health
- **Microphone**: Voice commands and speech recognition
- **Speech Recognition**: AI interaction
- **Photo Library**: Food scanning feature

## Development Notes

### AI Features
- AI features are automatically disabled if no API key is configured
- Graceful error handling prevents app crashes
- Users receive clear feedback when AI is unavailable

### Error Handling
- All Core Data operations are wrapped in proper error handling
- Network requests include timeout and retry logic
- Permission requests include fallback behavior

### Testing
- Builds successfully on iOS 18.5+ simulators
- Tested with iPhone 16 simulator
- All permissions properly configured

## Troubleshooting

### Build Issues
- Ensure Xcode 16+ is installed
- Clean build folder if encountering cache issues
- Verify all Swift Package dependencies are resolved

### Runtime Issues
- Check that API key is properly configured
- Verify permissions are granted in device settings
- Check console logs for detailed error information

### AI Features Not Working
- Verify API key is set correctly
- Check internet connectivity
- Review console logs for API error details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Git Version Control

### Quick Commands

**Save your changes:**
```bash
./backup.sh
```

**Check what files have changed:**
```bash
git status
```

**See recent changes:**
```bash
git log --oneline -10
```

**Revert to a previous version:**
```bash
# First, see the commit history
git log --oneline

# Then revert to a specific commit (replace COMMIT_HASH)
git reset --hard COMMIT_HASH
```

**Create a new branch for testing:**
```bash
git checkout -b feature-name
git checkout main  # Go back to main branch
```

### Manual Git Commands

**Save changes:**
```bash
git add .
git commit -m "Description of your changes"
```

**See what changed:**
```bash
git diff
```

**Undo last commit (but keep changes):**
```bash
git reset --soft HEAD~1
```

**Undo last commit (and discard changes):**
```bash
git reset --hard HEAD~1
```

## Project Structure

- `fit_buddy_mvp.swift` - Main app file with all functionality
- `backup.sh` - Script to easily save changes
- `.gitignore` - Excludes unnecessary files from version control

## Tips

- Run `./backup.sh` frequently to save your work
- Use descriptive commit messages
- Test changes on a branch before merging to main
- Keep your API key secure and never commit it to Git 