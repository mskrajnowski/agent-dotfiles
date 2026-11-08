#!/usr/bin/env bash
# Run a browser automation script with a project-local node environment.
#
# Usage: exec.sh <script.cjs> [args...]
#
# Uses a fixed work directory (/tmp/browser-skill) as the npm project root:
# puppeteer-core is installed there on first use, and scripts can pull in
# more dependencies with plain npm in that directory. Exports
# BROWSER_SKILL_DIR so scripts can load the skill's attach.cjs helper.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR=/tmp/browser-skill

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <script.cjs> [args...]" >&2
  exit 2
fi

if [[ ! -d $WORK_DIR/node_modules/puppeteer-core ]]; then
  echo "Preparing $WORK_DIR (installing puppeteer-core)..."
  mkdir -p "$WORK_DIR"
  (
    cd "$WORK_DIR"
    [[ -f package.json ]] || npm init --yes >/dev/null
    npm install --silent puppeteer-core
  )
fi

export NODE_PATH="$WORK_DIR/node_modules"
export BROWSER_SKILL_DIR="$SKILL_DIR"

exec node "$@"
