#!/bin/bash

# Peregrine Backup Script
# This script saves your current code changes to Git

echo "🏋️ Peregrine Backup Script"
echo "=========================="

# Check if there are any changes to commit
if git diff --quiet && git diff --cached --quiet; then
    echo "✅ No changes to commit - everything is up to date!"
else
    echo "📝 Changes detected, committing..."
    
    # Add all changes
    git add .
    
    # Get current timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Commit with timestamp
    git commit -m "Backup: $timestamp - $(git diff --cached --name-only | head -3 | tr '\n' ' ')"
    
    echo "✅ Changes saved successfully!"
    echo "📅 Timestamp: $timestamp"
fi

echo ""
echo "📊 Git Status:"
git status --short

echo ""
echo "🔄 Recent commits:"
git log --oneline -5 