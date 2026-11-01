#!/usr/bin/env bash
# Add a comment to an issue.
# Usage: comment_issue.sh <owner>/<repo> <index> <text|->
#   text "-" reads the comment body from stdin.
# Prints: new comment id on success.
set -euo pipefail

repo=${1:?usage: comment_issue.sh <owner>/<repo> <index> <text|->}
index=${2:?missing issue index}
text=${3:-}

if [[ ${text:-} == "-" ]]; then
  text=$(cat)
fi
[[ -n $text ]] || { echo "ERROR: empty comment text" >&2; exit 1; }

api=http://forge.local/api/v1/repos/${repo}/issues/${index}/comments
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --arg body "$text" '{body:$body}')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" -X POST \
  -H 'Content-Type: application/json' -d "$payload" "$api")

if [[ $code == 201 ]]; then
  jq -r '"Comment \(.id) added"' "$tmp"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
