#!/usr/bin/env bash
# Request (or re-request) a review for a pull request.
# Usage: request_pr_review.sh <owner>/<repo> <index> <username>...
# Prints: confirmation with the requested usernames on success.
set -euo pipefail

repo=${1:?usage: request_pr_review.sh <owner>/<repo> <index> <username>...}
index=${2:?missing PR index}
shift 2
[[ $# -ge 1 ]] || { echo "ERROR: missing reviewer username(s)" >&2; exit 1; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --argjson r "$(printf '%s\n' "$@" | jq -R . | jq -s .)" '{reviewers: $r}')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" \
  -X POST "http://forge.local/api/v1/repos/${repo}/pulls/${index}/requested_reviewers" \
  -H 'Content-Type: application/json' \
  -d "$payload")
[[ $code == 200 || $code == 201 ]] || { echo "ERROR: HTTP $code" >&2; jq -r '.message // empty' "$tmp" >&2; exit 1; }

echo "Review requested from: $*"
