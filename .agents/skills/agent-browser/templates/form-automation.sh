#!/bin/bash
# Template: Form Automation Workflow
# Fills and submits web forms with validation

set -euo pipefail

FORM_URL="${1:?Usage: $0 <form-url>}"

echo "Automating form at: $FORM_URL"

agent-browser open "$FORM_URL"
agent-browser wait --load networkidle

echo "Analyzing form structure..."
agent-browser snapshot -i

# Uncomment and modify refs based on snapshot output:
# agent-browser fill @e1 "John Doe"
# agent-browser fill @e2 "user@example.com"
# agent-browser fill @e3 "SecureP@ssw0rd!"
# agent-browser select @e4 "Option Value"
# agent-browser check @e5
# agent-browser click @e6  # Submit

# agent-browser wait --load networkidle

echo "Form submission result:"
agent-browser get url
agent-browser snapshot -i
agent-browser screenshot /tmp/form-result.png
agent-browser close
echo "Form automation complete"
