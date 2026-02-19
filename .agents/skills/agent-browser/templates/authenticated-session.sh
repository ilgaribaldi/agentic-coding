#!/bin/bash
# Template: Authenticated Session Workflow
# Login once, save state, reuse for subsequent runs
#
# Usage:
#   ./authenticated-session.sh <login-url> [state-file]

set -euo pipefail

LOGIN_URL="${1:?Usage: $0 <login-url> [state-file]}"
STATE_FILE="${2:-./auth-state.json}"

echo "Authentication workflow for: $LOGIN_URL"

if [[ -f "$STATE_FILE" ]]; then
    echo "Loading saved authentication state..."
    agent-browser state load "$STATE_FILE"
    agent-browser open "$LOGIN_URL"
    agent-browser wait --load networkidle

    CURRENT_URL=$(agent-browser get url)
    if [[ "$CURRENT_URL" != *"login"* ]] && [[ "$CURRENT_URL" != *"sign-in"* ]]; then
        echo "Session restored successfully!"
        agent-browser snapshot -i
        exit 0
    fi
    echo "Session expired, performing fresh login..."
    rm -f "$STATE_FILE"
fi

echo "Opening login page..."
agent-browser open "$LOGIN_URL"
agent-browser wait --load networkidle
agent-browser snapshot -i

echo ""
echo "Next steps:"
echo "  1. Note refs for username, password, submit fields"
echo "  2. Customize the login flow below"
echo ""

# Uncomment and customize:
# : "${APP_USERNAME:?Set APP_USERNAME environment variable}"
# : "${APP_PASSWORD:?Set APP_PASSWORD environment variable}"
#
# agent-browser fill @e1 "$APP_USERNAME"
# agent-browser fill @e2 "$APP_PASSWORD"
# agent-browser click @e3
# agent-browser wait --load networkidle
#
# agent-browser state save "$STATE_FILE"
# echo "Login successful!"

agent-browser close
