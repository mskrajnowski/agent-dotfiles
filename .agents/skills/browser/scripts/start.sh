#!/usr/bin/env bash
# Start a browser in the background with a debug port and a persistent
# profile, so automation scripts can attach to it (scripts/exec.sh).
# Idempotent: prints status if the browser is already running.
#
# Usage: start.sh [chromium|firefox] [--headless]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$HOME/.local/share/browser-skill"
# One background browser per engine; the ports are fixed so scripts and
# the attach helper can rely on them (state in $DATA_DIR records them).
CHROMIUM_PORT=9222
FIREFOX_PORT=9223

browser=chromium
headless=false
for arg in "$@"; do
  case $arg in
  chromium | firefox) browser=$arg ;;
  --headless) headless=true ;;
  *)
    echo "Unknown argument: $arg" >&2
    exit 2
    ;;
  esac
done

port=$CHROMIUM_PORT
[[ $browser == firefox ]] && port=$FIREFOX_PORT
STATE_FILE="$DATA_DIR/$browser.env"

browser_bin() {
  local candidates
  case $browser in
  chromium) candidates=(/opt/ms-playwright/chromium-*/chrome-linux64/chrome "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome) ;;
  firefox) candidates=(/opt/ms-playwright/firefox-*/firefox/firefox "$HOME"/.cache/ms-playwright/firefox-*/firefox/firefox) ;;
  esac
  local c
  for c in "${candidates[@]}"; do
    [[ -e $c ]] && {
      echo "$c"
      return 0
    }
  done
}

port_up() {
  (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null
}

status() {
  cat <<EOF

$browser running in the background.
  PID:           $(sed -n "s/^PID=//p" "$STATE_FILE" 2>/dev/null || echo '?')
  Debug port:    127.0.0.1:$port
  Profile:       $DATA_DIR/profiles/$browser
  State file:    $STATE_FILE

Attach from a script (see SKILL.md), e.g.:
  scripts/exec.sh examples/$browser-attach.cjs https://example.com
EOF
}

# Already up?
if [[ -f $STATE_FILE ]] && port_up; then
  echo "Browser already running."
  status
  exit 0
fi
# Stale state from a crashed/killed browser.
if [[ -f $STATE_FILE ]]; then
  echo "Stale state file; removing."
  rm -f "$STATE_FILE" "$DATA_DIR/$browser.log"
fi
# The port must be free before we launch, otherwise scripts would attach to
# whatever process happens to hold it (wrong profile).
if port_up; then
  echo "ERROR: port $port is already in use by another process; free it first:" >&2
  echo "  scripts/stop.sh $browser   # if stop.sh reports 'not running', recover with:" >&2
  echo "  pkill -f -- '--remote-debugging-port=$port'" >&2
  exit 1
fi

bin=$(browser_bin)
if [[ -z $bin ]]; then
  echo "ERROR: no $browser binary found; the sandbox image should provide" >&2
  echo "it at /opt/ms-playwright (see the agent-kit Dockerfile in the dotfiles repo)." >&2
  exit 1
fi

mkdir -p "$DATA_DIR/profiles/$browser"

# Headed mode needs the desktop session (the browser window lives there).
if [[ $headless == false ]]; then
  if [[ ! -x $SKILL_DIR/../desktop/scripts/start.sh ]]; then
    echo "ERROR: headed mode needs the desktop skill's session; use" >&2
    echo "--headless or install the desktop skill." >&2
    exit 1
  fi
  "$SKILL_DIR/../desktop/scripts/start.sh" >/dev/null
fi

launch_args=()
case $browser in
chromium)
  # --disable-infobars is a Chrome for Testing-only switch (branded Chrome
  # removed it in 2019) that hides the "only for automated testing" bar.
  launch_args=(--remote-debugging-port="$port"
    --user-data-dir="$DATA_DIR/profiles/$browser"
    --no-first-run --no-default-browser-check
    --disable-infobars
    --enable-unsafe-swiftshader)
  [[ $headless == true ]] && launch_args+=(--headless)
  ;;
firefox)
  launch_args=(-profile "$DATA_DIR/profiles/$browser"
    -no-remote --remote-debugging-port "$port")
  [[ $headless == true ]] && launch_args+=(-headless)
  ;;
esac

# In headed mode the browser window lives in the desktop session, so it is
# launched through that session's environment wrapper.
if [[ $headless == false ]]; then
  setsid "$SKILL_DIR/../desktop/scripts/run.sh" "$bin" "${launch_args[@]}" about:blank \
    >"$DATA_DIR/$browser.log" 2>&1 </dev/null &
else
  setsid "$bin" "${launch_args[@]}" about:blank \
    >"$DATA_DIR/$browser.log" 2>&1 </dev/null &
fi
pid=$!

# Firefox serves WebDriver BiDi (plain HTTP GET answers 400); chromium
# serves CDP with /json/version. Both only after the port accepts TCP.
ok=false
for _ in $(seq 1 100); do
  if port_up; then
    ok=true
    break
  fi
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.2
done
if [[ $ok != true ]] || ! kill -0 "$pid" 2>/dev/null; then
  echo "ERROR: $browser did not open its debug port; log:" >&2
  cat "$DATA_DIR/$browser.log" >&2
  exit 1
fi

{
  echo "PORT=$port"
  echo "PID=$pid"
  echo "PROFILE=$DATA_DIR/profiles/$browser"
} >"$STATE_FILE"

status
