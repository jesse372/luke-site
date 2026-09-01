#!/bin/bash
# Serves Luke's site and exposes it via a Cloudflare quick tunnel.
# launchd keeps this alive; if it dies it restarts and writes the new URL to LINK.txt
DIR="$HOME/JesseOS/projects/luke-site"
PORT=54661
LOG=/tmp/luke_tunnel.log
if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
  cd "$DIR"
  nohup python3 -m http.server $PORT --bind 127.0.0.1 >/tmp/luke_http.log 2>&1 &
  sleep 1
fi
: > "$LOG"
"$DIR/bin/cloudflared" tunnel --url http://127.0.0.1:$PORT --no-autoupdate >>"$LOG" 2>&1 &
CFPID=$!
for i in $(seq 1 30); do
  u=$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" | head -1)
  [ -n "$u" ] && { echo "$u" > "$DIR/LINK.txt"; break; }
  sleep 1
done
wait $CFPID
