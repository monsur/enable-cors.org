#!/bin/bash

# Script to automatically process all uncompleted CORS documentation files
# Each file is processed by a fresh agent with its own context

set -e

echo "======================================"
echo "CORS Documentation Auto-Processor"
echo "======================================"
echo ""

# Function to get list of uncompleted files
get_uncompleted_files() {
  cd claude
  grep -l "Status:" *.md | while read fname; do
    if ! grep -q "^\*\*Status:\*\* ✅" "$fname"; then
      echo "$fname"
    fi
  done
  cd ..
}

# Get all uncompleted files
UNCOMPLETED_FILES=$(get_uncompleted_files)

if [ -z "$UNCOMPLETED_FILES" ]; then
  echo "✅ All files are already complete!"
  exit 0
fi

# Count total files
TOTAL=$(echo "$UNCOMPLETED_FILES" | wc -l | tr -d ' ')
echo "Found $TOTAL uncompleted file(s) to process:"
echo ""
echo "$UNCOMPLETED_FILES" | nl
echo ""
echo "======================================"
echo ""

# Process each file
COUNTER=1
echo "$UNCOMPLETED_FILES" | while read MD_FILE; do
  echo ""
  echo "[$COUNTER/$TOTAL] Processing: $MD_FILE"
  echo "--------------------------------------"

  # Run claude with the task for this file (print mode exits automatically, acceptEdits skips confirmations)
  claude --print --permission-mode acceptEdits "Read the file claude/$MD_FILE and implement all the recommendations in the corresponding HTML file.

After implementing the changes:
1. Commit the changes with a descriptive message that references any GitHub issues mentioned in the .md file (to auto-close them when pushed)
2. Update the .md file to mark it as \"✅ COMPLETED - Implemented January 2025\"
3. Commit the documentation update in a separate commit

Follow the same pattern as was done for server_appengine.html and server_awsapigateway.html."

  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Successfully processed $MD_FILE"
  else
    echo "❌ Failed to process $MD_FILE (exit code: $EXIT_CODE)"
    echo ""
    echo "Do you want to continue with the next file? (y/n)"
    read -r CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
      echo "Stopping automation."
      exit 1
    fi
  fi

  COUNTER=$((COUNTER + 1))
  echo ""
done

echo ""
echo "======================================"
echo "✅ All files processed!"
echo "======================================"
echo ""
echo "To review the changes:"
echo "  git log --oneline"
echo ""
echo "To push to remote:"
echo "  git push origin updates"
