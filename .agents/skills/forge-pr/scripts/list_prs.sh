#!/usr/bin/env bash
# List pull requests on the forge.
# Usage: list_prs.sh <owner>/<repo> [state]   state: open|closed|all (default open)
# Prints: one line per PR: "#index [state] title (head->base)"
set -euo pipefail

repo=${1:?usage: list_prs.sh <owner>/<repo> [state]}
state=${2:-open}

api="http://forge.local/api/v1/repos/${repo}/pulls?state=${state}&limit=50"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$api")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

jq -r '.[] | "#\(.number) [\(.state)] \(.title) (\(.head.ref)->\(.base.ref))"' "$tmp"
