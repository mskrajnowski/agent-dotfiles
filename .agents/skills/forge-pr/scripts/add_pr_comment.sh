#!/usr/bin/env bash
# Add a general comment to a pull request (PRs are issues on the forge).
# Usage: add_pr_comment.sh <owner>/<repo> <index> <text|->
#   text "-" reads the comment body from stdin.
# Prints: new comment id on success.
set -euo pipefail

repo=${1:?usage: add_pr_comment.sh <owner>/<repo> <index> <text|->}
index=${2:?missing PR index}
text=${3:-}

[[ -n $text ]] || { echo "ERROR: missing comment text" >&2; exit 1; }
if [[ $text == - ]]; then text=$(cat); fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" \
  -X POST "http://forge.local/api/v1/repos/${repo}/issues/${index}/comments" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg b "$text" '{body: $b}')")

if [[ $code == 201 ]]; then
  jq -r '"Comment \(.id) added"' "$tmp"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
