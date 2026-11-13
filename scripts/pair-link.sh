#!/usr/bin/env bash
# Print a one-time browser login link for the running OpenCode server.
# Run this inside the Render Shell (Dashboard -> your service -> Shell).
set -euo pipefail

PORT="${PORT:-4096}"
: "${OPENCODE_PASSWORD:?OPENCODE_PASSWORD is not set in this shell}"

code="$(curl -s -u "opencode:${OPENCODE_PASSWORD}" -X POST "http://127.0.0.1:${PORT}/api/pair" \
        | sed -E 's/.*"code":"([^"]+)".*/\1/')"

if [ -z "$code" ] || [ "$code" = "null" ]; then
  echo "Could not create a pairing code. Is the server running on port ${PORT}?" >&2
  exit 1
fi

echo
echo "Login link (valid ~5 minutes):"
echo "  https://<YOUR-SERVICE>.onrender.com/auth/connect/${code}"
echo
echo "Replace <YOUR-SERVICE> with your Render URL, then open it in a browser."
