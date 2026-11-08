#!/usr/bin/env bash
# Start a long-running headless Wayland desktop session (sway) in the sandbox.
# Idempotent: prints the running session's details if one is already up.
set -euo pipefail

SESSION_DIR="/run/user/$(id -u)/desktop-session"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# wayvnc only serves websockify inside the sandbox and never gets published.
VNC_PORT=5900
# The sandbox always serves the desktop on the noVNC default port;
# agent-desktop publishes it on a free host port of its choosing.
NOVNC_PORT=6080

sway_pid() {
  local pidfile="$SESSION_DIR/sway.pid"
  [[ -f $pidfile ]] || return 1
  local pid
  pid=$(cat "$pidfile") || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  echo "$pid"
}

novnc_up() {
  (exec 3<>"/dev/tcp/127.0.0.1/$NOVNC_PORT") 2>/dev/null
}

status() {
  local novnc_line
  if novnc_up; then
    novnc_line="  noVNC (web):   0.0.0.0:$NOVNC_PORT"
  else
    novnc_line="  noVNC (web):   NOT LISTENING — see $SESSION_DIR/websockify.log"
  fi
  cat <<EOF

Desktop session running.
  Sway:          PID $(sway_pid), socket $SESSION_DIR/wayland-1
$novnc_line
  App env:       source $SESSION_DIR/env (or use scripts/run.sh)

Share with the host (agent-desktop runs on the host machine):
  agent-desktop <sandbox-name>
EOF
}

if pid=$(sway_pid); then
  echo "Session already running (sway PID $pid)."
  status
  exit 0
fi

# Ensure the desktop packages are present. They ship in the agent-kit image;
# older sandboxes install them on demand here.
missing=()
for cmd in sway wayvnc grim websockify Xwayland; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
  echo "Installing missing desktop packages (${missing[*]})..."
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends sway wayvnc grim xwayland novnc websockify
fi

# Remove leftovers from a previous session (lock files make sockets unavailable).
rm -rf "$SESSION_DIR"
mkdir -p "$SESSION_DIR"

# WAYLAND_DISPLAY from the ambient environment points at the clipboard bridge's
# socket and must not influence sway's socket choice. sway allocates wayland-1
# (it skips the clipboard bridge's wayland-0), which is what the session env
# file exports for clients.
setsid env -u WAYLAND_DISPLAY -u DISPLAY \
  WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  XDG_RUNTIME_DIR="$SESSION_DIR" \
  sway -c "$SKILL_DIR/sway.conf" >"$SESSION_DIR/sway.log" 2>&1 </dev/null &
echo $! >"$SESSION_DIR/sway.pid"

sway_pid=$(cat "$SESSION_DIR/sway.pid")
for _ in $(seq 1 50); do
  [[ -S $SESSION_DIR/wayland-1 ]] && break
  kill -0 "$sway_pid" 2>/dev/null || break
  sleep 0.2
done
if [[ ! -S $SESSION_DIR/wayland-1 ]]; then
  echo "ERROR: sway did not start; log follows:" >&2
  cat "$SESSION_DIR/sway.log" >&2
  exit 1
fi
ipc_socket=$(find "$SESSION_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit 2>/dev/null || true)

{
  echo "XDG_RUNTIME_DIR=$SESSION_DIR"
  echo "WAYLAND_DISPLAY=wayland-1"
  echo "SWAYSOCK=$ipc_socket"
  # X display for X11 clients, hardcoded to :0: this session is the sandbox's
  # main (and only) desktop. Tooling that needs another X server is responsible
  # for picking a different display number.
  echo "DISPLAY=:0"
} >"$SESSION_DIR/env"

setsid env XDG_RUNTIME_DIR="$SESSION_DIR" WAYLAND_DISPLAY=wayland-1 \
  wayvnc -R 127.0.0.1 "$VNC_PORT" >"$SESSION_DIR/wayvnc.log" 2>&1 </dev/null &

if [[ -d /usr/share/novnc ]]; then
  setsid websockify --web=/usr/share/novnc "$NOVNC_PORT" "localhost:$VNC_PORT" \
    >"$SESSION_DIR/websockify.log" 2>&1 </dev/null &
fi

# Give websockify a moment to bind so the status below is accurate.
for _ in $(seq 1 10); do
  novnc_up && break
  sleep 0.2
done

status
