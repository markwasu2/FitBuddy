# FitBuddy - AI-Powered Fitness Assistant

A SwiftUI iOS app that uses Google's Gemini AI to create personalized workout plans.

## Features

- 🤖 AI-powered workout plan generation
- 📅 Calendar integration for scheduling workouts
- 📱 Modern SwiftUI interface
- 🏋️ Structured workout templates
- 📸 Food calorie scanning (placeholder)

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

## Setup

1. Open the project in Xcode
2. Add your Gemini API key to environment variables
3. Build and run

## API Key Setup

In Xcode:
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add: `GEMINI_API_KEY` = `your_api_key_here`

## Project Structure

- `fit_buddy_mvp.swift` - Main app file with all functionality
- `backup.sh` - Script to easily save changes
- `.gitignore` - Excludes unnecessary files from version control

## Tips

- Run `./backup.sh` frequently to save your work
- Use descriptive commit messages
- Test changes on a branch before merging to main
- Keep your API key secure and never commit it to Git 