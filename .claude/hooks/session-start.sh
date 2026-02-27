#!/bin/bash
set -euo pipefail

# Start dolt sql-server for beads (bd) issue tracking if not already running.
# The server must be on port 3307 with the servicetalk beads data directory.

DOLT_PORT=3307
DOLT_DATA_DIR="/home/user/servicetalk/.beads/dolt"

# Check if dolt sql-server is already listening on port 3307
if ss -tlnp 2>/dev/null | grep -q ":${DOLT_PORT} " || \
   netstat -tlnp 2>/dev/null | grep -q ":${DOLT_PORT} "; then
  echo "dolt sql-server already running on port ${DOLT_PORT}, skipping start."
  exit 0
fi

# Also check via pgrep in case ss/netstat aren't available
if pgrep -f "dolt sql-server.*--port ${DOLT_PORT}" > /dev/null 2>&1; then
  echo "dolt sql-server process already running on port ${DOLT_PORT}, skipping start."
  exit 0
fi

echo "Starting dolt sql-server on port ${DOLT_PORT}..."
nohup dolt sql-server \
  --port "${DOLT_PORT}" \
  --loglevel error \
  --data-dir "${DOLT_DATA_DIR}" \
  > /tmp/dolt-sql-server.log 2>&1 &

DOLT_PID=$!
echo "dolt sql-server started with PID ${DOLT_PID}"

# Wait for the server to become ready (up to 10 seconds)
echo "Waiting for dolt sql-server to be ready..."
for i in $(seq 1 10); do
  if ss -tlnp 2>/dev/null | grep -q ":${DOLT_PORT} " || \
     netstat -tlnp 2>/dev/null | grep -q ":${DOLT_PORT} "; then
    echo "dolt sql-server is ready on port ${DOLT_PORT}."
    exit 0
  fi
  sleep 1
done

# Final check — if still not up, warn but don't fail the session
if pgrep -f "dolt sql-server.*--port ${DOLT_PORT}" > /dev/null 2>&1; then
  echo "dolt sql-server process is running (port may still be binding). Continuing."
else
  echo "WARNING: dolt sql-server may not have started correctly. Check /tmp/dolt-sql-server.log"
fi
