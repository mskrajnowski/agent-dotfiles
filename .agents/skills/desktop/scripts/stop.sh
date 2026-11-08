#!/usr/bin/env bash
# Stop the headless Wayland desktop session.
set -euo pipefail

SESSION_DIR="/run/user/$(id -u)/desktop-session"

if [[ ! -f $SESSION_DIR/sway.pid ]] || ! kill -0 "$(cat "$SESSION_DIR/sway.pid")" 2>/dev/null; then
  echo "No desktop session running."
  rm -rf "$SESSION_DIR"
  exit 0
fi

sway_pid=$(cat "$SESSION_DIR/sway.pid")
ipc_socket=$(find "$SESSION_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit 2>/dev/null || true)
if [[ -n $ipc_socket ]]; then
  SWAYSOCK="$ipc_socket" XDG_RUNTIME_DIR="$SESSION_DIR" swaymsg exit >/dev/null 2>&1 || true
fi

# Fall back to SIGTERM if graceful exit does not finish within ~5s.
for _ in $(seq 1 25); do
  kill -0 "$sway_pid" 2>/dev/null || break
  sleep 0.2
done
if kill -0 "$sway_pid" 2>/dev/null; then
  kill "$sway_pid" 2>/dev/null || true
fi

# Sway owns wayvnc's wayland connection; websockify is independent, so clean
# up both by process match. These helpers only run for the desktop session.
pkill -x sway 2>/dev/null || true
pkill -x wayvnc 2>/dev/null || true
pkill -f 'websockify --web=/usr/share/novnc' 2>/dev/null || true

rm -rf "$SESSION_DIR"
echo "Desktop session stopped."
