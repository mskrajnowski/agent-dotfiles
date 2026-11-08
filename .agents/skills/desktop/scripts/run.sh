#!/usr/bin/env bash
# Run a command inside the desktop session, with the Wayland/X11 environment set.
# Usage: run.sh <command> [args...]
# Example: run.sh foot   |   run.sh grim /tmp/desktop.png
set -euo pipefail

SESSION_DIR="/run/user/$(id -u)/desktop-session"

if [[ ! -f $SESSION_DIR/env ]]; then
  echo "ERROR: no desktop session; start one with scripts/start.sh first." >&2
  exit 1
fi
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "$SESSION_DIR/env"

# shellcheck disable=SC1091
source "$SESSION_DIR/env"

exec env XDG_RUNTIME_DIR="$SESSION_DIR" \
  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  SWAYSOCK="$SWAYSOCK" \
  DISPLAY="$DISPLAY" \
  XDG_SESSION_TYPE=wayland \
  "$@"
