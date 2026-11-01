#!/usr/bin/env bash
# List issues on the forge.
# Usage: list_issues.sh <owner>/<repo> [state]   state: open|closed|all (default open)
# Prints: one line per issue: "#index [state] title"
set -euo pipefail

repo=${1:?usage: list_issues.sh <owner>/<repo> [state]}
state=${2:-open}

api="http://forge.local/api/v1/repos/${repo}/issues?state=${state}&limit=50&type=issues"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$api")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

jq -r '.[] | "#\(.number) [\(.state)] \(.title)"' "$tmp"
