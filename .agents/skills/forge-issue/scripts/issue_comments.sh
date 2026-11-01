#!/usr/bin/env bash
# Fetch comments for an issue.
# Usage: issue_comments.sh <owner>/<repo> <index>
# Prints: id, author, and body (truncated to 3 lines) per comment.
set -euo pipefail

repo=${1:?usage: issue_comments.sh <owner>/<repo> <index>}
index=${2:?missing issue index}

api=http://forge.local/api/v1/repos/${repo}/issues/${index}/comments
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$api")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

jq -r '.[] |
  "COMMENT \(.id) by \(.user.login) at \(.created_at)",
  (.body | split("\n")[:3] | "  " + join("\n  ")),
  "---"' "$tmp"
