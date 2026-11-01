#!/usr/bin/env bash
# Update a pull request's title, body, and/or state.
# Usage: update_pr.sh <owner>/<repo> <pr-index> [--title <text>] [--body <text|-|->] [--state open|closed]
#   --body -  reads the body from stdin.
# Prints: confirmation on success.
set -euo pipefail

repo=${1:?usage: update_pr.sh <owner>/<repo> <pr-index> [--title t] [--body t|-] [--state open|closed]}
index=${2:?missing PR index}
shift 2

title=""; body=""; state=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --title) title=${2:?missing value}; shift 2 ;;
    --body)  body=${2:?missing value}; shift 2 ;;
    --state) state=${2:?missing value}; shift 2 ;;
    *) echo "ERROR: unknown option $1" >&2; exit 1 ;;
  esac
done
[[ -n $title$state$body ]] || { echo "ERROR: nothing to update" >&2; exit 1; }
if [[ $body == - ]]; then body=$(cat); fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

payload=$(jq -n --arg t "$title" --arg b "$body" --arg s "$state" \
  '{title: $t, body: $b, state: $s} | with_entries(select(.value != ""))')

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" \
  -X PATCH "http://forge.local/api/v1/repos/${repo}/pulls/${index}" \
  -H 'Content-Type: application/json' \
  -d "$payload")

if [[ $code == 200 || $code == 201 ]]; then
  echo "PR #${index} updated"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp" >&2
  exit 1
fi
