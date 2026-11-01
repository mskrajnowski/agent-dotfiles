#!/usr/bin/env bash
# Create an issue on the forge.
# Usage: open_issue.sh <owner>/<repo> <title> [body|-]
# Prints: issue number and URL on success, error summary on failure.
set -euo pipefail

repo=${1:?usage: open_issue.sh <owner>/<repo> <title> [body|-]}
title=${2:?missing title}
body=${3:-}

if [[ ${body:-} == "-" ]]; then
  body=$(cat)
fi

api=http://forge.local/api/v1/repos/${repo}/issues
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --arg title "$title" --arg body "$body" '{title:$title, body:$body}')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" -X POST \
  -H 'Content-Type: application/json' -d "$payload" "$api")

if [[ $code == 201 ]]; then
  jq -r '"Issue #\(.number) opened: \(.html_url)"' "$tmp"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
