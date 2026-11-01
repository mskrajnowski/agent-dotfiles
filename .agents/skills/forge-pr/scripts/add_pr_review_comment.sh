#!/usr/bin/env bash
# Add an inline review comment at a specific file and line.
# Usage: add_pr_review_comment.sh <owner>/<repo> <pr-index> <path> <line> <text|->
#   line: line number in the new version of the file.
#   text "-" reads the comment body from stdin.
# Prints: review id and comment id on success.
set -euo pipefail

repo=${1:?usage: add_pr_review_comment.sh <owner>/<repo> <pr-index> <path> <line> <text|->}
index=${2:?missing PR index}
path=${3:?missing file path}
line=${4:?missing line number}
text=${5:-}

[[ -n $text ]] || { echo "ERROR: missing comment text" >&2; exit 1; }
if [[ $text == - ]]; then text=$(cat); fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --arg p "$path" --arg b "$text" --arg l "$line" \
  '{event: "COMMENT", comments: [{path: $p, new_position: ($l|tonumber), body: $b}]}')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" \
  -X POST "http://forge.local/api/v1/repos/${repo}/pulls/${index}/reviews" \
  -H 'Content-Type: application/json' \
  -d "$payload")

if [[ $code == 200 ]]; then
  review_id=$(jq -r '.id' "$tmp")
  echo "Review comment added on $path:$line (review $review_id)"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
