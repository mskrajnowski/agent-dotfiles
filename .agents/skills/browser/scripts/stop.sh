#!/usr/bin/env bash
# Stop a background browser started with scripts/start.sh.
# Usage: stop.sh [chromium|firefox|all]
set -euo pipefail

DATA_DIR="$HOME/.local/share/browser-skill"

target="${1:-all}"
case $target in
chromium | firefox | all) ;;
*)
  echo "Usage: $0 [chromium|firefox|all]" >&2
  exit 2
  ;;
esac

stop_one() {
  local browser=$1 state_file="$DATA_DIR/$1.env" port
  if [[ ! -f $state_file ]]; then
    # No state, but the debug port may be held by an orphan (state file
    # deleted or lost after a crash). Recover it best-effort.
    case $browser in
    chromium) port=9222 ;;
    firefox) port=9223 ;;
    esac
    # Matches both flag spellings (=port for chromium, space port for
    # firefox); SIGTERM to the main process takes the renderers with it.
    if pkill -TERM -f "remote-debugging-port[= ]$port"; then
      echo "$browser: orphaned browser killed; no state file existed."
    else
      echo "$browser: not running."
    fi
    return 0
  fi
  # shellcheck disable=SC1090
  source "$state_file"
  # Graceful close through the debug protocol first: the browser flushes
  # cookies and session state to the profile (it otherwise commits lazily,
  # up to ~30s, and a signal kill loses fresh state). exec.sh owns the npm
  # work dir that provides puppeteer-core for close.cjs; on a wiped /tmp it
  # pays one npm install, offline it fails and signals take over.
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  "$script_dir/exec.sh" "$script_dir/close.cjs" "$browser" >/dev/null 2>&1 || true
  # Let the browser finish its own shutdown first — firefox writes session
  # state asynchronously after the close command, and an early SIGTERM
  # cuts that write off. Only escalate if it does not exit in time.
  exited=false
  for _ in $(seq 1 50); do
    if ! kill -0 "$PID" 2>/dev/null; then
      exited=true
      break
    fi
    sleep 0.2
  done
  if [[ $exited != true ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    for _ in $(seq 1 25); do
      kill -0 "$PID" 2>/dev/null || break
      sleep 0.2
    done
    kill -9 "$PID" 2>/dev/null || true
  fi
  rm -f "$state_file" "$DATA_DIR/$browser.log"
  echo "$browser: stopped (profile kept at $PROFILE)."
}

case $target in
all)
  stop_one chromium
  stop_one firefox
  ;;
*) stop_one "$target" ;;
esac
