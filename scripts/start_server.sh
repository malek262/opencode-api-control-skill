#!/bin/bash
# Start OpenCode Web Server in background with a pseudo-TTY
# This ensures it survives when the parent process (Agent) exits.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$SKILL_DIR/opencode_server.log"
PORT=4099

# Check if server is already running
if curl -s "http://127.0.0.1:$PORT/global/health" | jq -e '.healthy' >/dev/null 2>&1; then
    echo "✓ OpenCode server is already running on port $PORT."
    exit 0
fi

echo "Starting OpenCode server on port $PORT..."

# Use 'script' to provide a fake TTY and 'nohup' to background it
# This handles the SIGKILL issue when started from non-interactive shells
nohup script -q -c "opencode web --port $PORT" /dev/null > "$LOG_FILE" 2>&1 &

echo "Waiting for server to initialize..."
MAX_ATTEMPTS=45
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "http://127.0.0.1:$PORT/global/health" | jq -e '.healthy' >/dev/null 2>&1; then
        echo "✓ Server successfully started and ready."
        exit 0
    fi
    ATTEMPT=$((ATTEMPT + 1))
    sleep 1
done

echo "❌ Error: Server failed to start within $MAX_ATTEMPTS seconds."
echo "Check $LOG_FILE for details."
exit 1
