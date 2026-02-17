#!/bin/bash
# Get session file changes

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


# Get diff
curl -s "$BASE_URL/session/$SESSION_ID/diff?directory=$PROJECT_PATH" | \
  jq -r '.[] | "\(.status): \(.file) (+\(.additions)/-\(.deletions))"'

exit 0