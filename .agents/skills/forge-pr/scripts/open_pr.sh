#!/usr/bin/env bash
# Open a pull request on the forge.
# Usage: open_pr.sh <owner>/<repo> <head> <base> <title> [body|-]
# Prints: PR number and URL on success, error summary on failure.
set -euo pipefail

repo=${1:?usage: open_pr.sh <owner>/<repo> <head> <base> <title> [body|-]}
head=${2:?missing head branch}
base=${3:?missing base branch}
title=${4:?missing title}
body=${5:-}

if [[ ${body:-} == "-" ]]; then
  body=$(cat)
fi

api=http://forge.local/api/v1/repos/${repo}/pulls
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --arg head "$head" --arg base "$base" --arg title "$title" \
  --arg body "$body" '{head:$head, base:$base, title:$title, body:$body}')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" -X POST \
  -H 'Content-Type: application/json' -d "$payload" "$api")

if [[ $code == 201 ]]; then
  jq -r '"PR #\(.number) opened: \(.html_url)"' "$tmp"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
