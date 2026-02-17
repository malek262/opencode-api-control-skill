#!/bin/bash
# Check session status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Load state
if [ ! -f "$SKILL_DIR/state/current.json" ]; then
  echo "Error: No active session" >&2
  exit 1
fi

SESSION_ID=$(jq -r '.session_id' "$SKILL_DIR/state/current.json")
PROJECT_PATH=$(jq -r '.project_path' "$SKILL_DIR/state/current.json")
BASE_URL=$(jq -r '.base_url' "$SKILL_DIR/state/current.json")
PASSWORD=$(jq -r '.password' "$SKILL_DIR/state/current.json")
[ "$PASSWORD" = "null" ] && PASSWORD=""

# Get status
if [ -n "$PASSWORD" ]; then
  STATUS=$(curl -s "$BASE_URL/session/status?directory=$PROJECT_PATH" \
    -H "Authorization: Bearer $PASSWORD" | \
    jq -r --arg sid "$SESSION_ID" '.[$sid].type')
else
  STATUS=$(curl -s "$BASE_URL/session/status?directory=$PROJECT_PATH" | \
    jq -r --arg sid "$SESSION_ID" '.[$sid].type')
fi

echo "$STATUS"
exit 0