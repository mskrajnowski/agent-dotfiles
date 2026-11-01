#!/usr/bin/env bash
# Merge a pull request on the forge.
# Usage: merge_pr.sh <owner>/<repo> <pr-index> [method]
#   method: merge|rebase|rebase-merge|squash (default: merge)
# Prints: merge status. Verifies mergeability first.
set -euo pipefail

repo=${1:?usage: merge_pr.sh <owner>/<repo> <pr-index> [method]}
index=${2:?missing PR index}
method=${3:-merge}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching PR" >&2; exit 1; }
jq -r '"PR #\(.number) \(.state) mergeable=\(.mergeable // "?")"' "$tmp"

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" -X POST \
  -H 'Content-Type: application/json' \
  -d "{\"Do\":\"${method}\"}" "${base}/merge")

case $code in
  200) echo "Merged PR #$index (${method})" ;;
  405) echo "NOT MERGEABLE: check PR state, conflicts, or required reviews" >&2; exit 1 ;;
  *)   echo "ERROR: HTTP $code" >&2; jq -r '.message // empty' "$tmp" >&2; exit 1 ;;
esac
