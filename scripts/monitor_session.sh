#!/bin/bash
# Monitor OpenCode session events

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

echo "Monitoring session: $SESSION_ID"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

# Stream events
if [ -n "$PASSWORD" ]; then
  curl -N "$BASE_URL/event?directory=$PROJECT_PATH" \
    -H "Authorization: Bearer $PASSWORD" 2>/dev/null
else
  curl -N "$BASE_URL/event?directory=$PROJECT_PATH" 2>/dev/null
fi | while IFS= read -r line; do
  if [[ $line == data:* ]]; then
    EVENT_DATA="${line#data:}"
    
    # Filter for this session
    EVENT_SESSION=$(echo "$EVENT_DATA" | jq -r '.payload.properties.sessionID // empty' 2>/dev/null)
    
    if [ "$EVENT_SESSION" = "$SESSION_ID" ] || [ -z "$EVENT_SESSION" ]; then
      EVENT_TYPE=$(echo "$EVENT_DATA" | jq -r '.payload.type' 2>/dev/null)
      
      case "$EVENT_TYPE" in
        "message.part.updated")
          DELTA=$(echo "$EVENT_DATA" | jq -r '.payload.properties.delta // empty' 2>/dev/null)
          [ -n "$DELTA" ] && echo -n "$DELTA"
          ;;
        "session.status")
          STATUS=$(echo "$EVENT_DATA" | jq -r '.payload.properties.status.type' 2>/dev/null)
          case "$STATUS" in
            "idle")
              echo -e "\n✓ Task completed"
              exit 0
              ;;
            "busy")
              echo -ne "\r⟳ Processing..."
              ;;
          esac
          ;;
        "message.updated")
          TOKENS=$(echo "$EVENT_DATA" | jq -r '.payload.properties.info.tokens.total // empty' 2>/dev/null)
          COST=$(echo "$EVENT_DATA" | jq -r '.payload.properties.info.cost // empty' 2>/dev/null)
          [ -n "$TOKENS" ] && echo -e "\n📊 Tokens: $TOKENS, Cost: \$$COST"
          ;;
      esac
    fi
  fi
done

exit 0