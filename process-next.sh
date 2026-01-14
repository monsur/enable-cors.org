#!/bin/bash

# Find the next uncompleted .md file
NEXT_FILE=$(cd claude && grep -l "Status:" *.md | while read fname; do
  if ! grep -q "^\*\*Status:\*\* ✅" "$fname"; then
    echo "$fname"
    exit 0
  fi
done | head -1)

if [ -z "$NEXT_FILE" ]; then
  echo "All files are complete!"
  exit 0
fi

echo "Next file to process: $NEXT_FILE"
echo ""
echo "To process this file, run:"
echo ""
echo "claude --print --auto 'Process claude/$NEXT_FILE: Read it and implement all recommendations in the corresponding HTML file. Commit changes referencing any GitHub issues, then mark the .md file as completed in a separate commit.'"
