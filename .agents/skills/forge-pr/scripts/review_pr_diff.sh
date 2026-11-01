#!/usr/bin/env bash
# Show the diff of a pull request (what the PR changes).
# Usage: review_pr_diff.sh <owner>/<repo> <index> [mode]
#   mode: diff (default) — full unified diff
#         stats          — one line per changed file (adds/deletes)
# Prints: the diff, or file stats, to stdout.
set -euo pipefail

repo=${1:?usage: review_pr_diff.sh <owner>/<repo> <index> [diff|stats]}
index=${2:?missing PR index}
mode=${3:-diff}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [[ $mode == stats ]]; then
  code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}/files?limit=200")
  [[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching files" >&2; exit 1; }
  jq -r '.[] | "\(.filename)  +\(.additions) -\(.deletions)\(if .previous_filename then " (renamed from \(.previous_filename))" else "" end)"' "$tmp"
  exit 0
fi

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}.diff")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching diff" >&2; exit 1; }
cat "$tmp"
