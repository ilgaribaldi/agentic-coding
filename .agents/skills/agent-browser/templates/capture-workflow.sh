#!/bin/bash
# Template: Content Capture Workflow
# Extract content from web pages with optional authentication

set -euo pipefail

TARGET_URL="${1:?Usage: $0 <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"

echo "Capturing content from: $TARGET_URL"
mkdir -p "$OUTPUT_DIR"

# Optional: Load authentication state
# agent-browser state load "./auth-state.json"

agent-browser open "$TARGET_URL"
agent-browser wait --load networkidle

echo "Page title: $(agent-browser get title)"
echo "Page URL: $(agent-browser get url)"

agent-browser screenshot --full "$OUTPUT_DIR/page-full.png"
echo "Screenshot saved: $OUTPUT_DIR/page-full.png"

agent-browser snapshot -i > "$OUTPUT_DIR/page-structure.txt"
echo "Structure saved: $OUTPUT_DIR/page-structure.txt"

agent-browser get text body > "$OUTPUT_DIR/page-text.txt"
echo "Text content saved: $OUTPUT_DIR/page-text.txt"

agent-browser pdf "$OUTPUT_DIR/page.pdf"
echo "PDF saved: $OUTPUT_DIR/page.pdf"

agent-browser close

echo ""
echo "Capture complete! Files saved to: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
