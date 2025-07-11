#!/bin/bash

# Autosave script: commits and pushes all changes every hour
# Usage: ./autosave.sh &

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  git add .
  git commit -m "[AUTOSAVE] Code autosaved at $TIMESTAMP" || echo "Nothing to commit at $TIMESTAMP"
  git push
  echo "[AUTOSAVE] Code pushed at $TIMESTAMP"
  sleep 3600 # Wait for 1 hour

done 