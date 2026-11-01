#!/usr/bin/env bash
# Fetch reviews and review comments for a PR, flattened for agent use.
# Usage: review_pr_comments.sh <owner>/<repo> <index>
# Prints: review states, then each comment: id, resolved status, file:line,
# author, and body. Body is truncated to 3 lines.
set -euo pipefail

repo=${1:?usage: review_pr_comments.sh <owner>/<repo> <index>}
index=${2:?missing PR index}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}
tmp=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp" "$tmp2"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}/reviews")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching reviews" >&2; exit 1; }

jq -r '.[] | "REVIEW \(.id) \(.state // "PENDING") by \(.user.login) official=\(.official)"' "$tmp"

for review_id in $(jq -r '.[].id' "$tmp"); do
  code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/reviews/${review_id}/comments")
  [[ $code == 200 ]] || { echo "WARN: HTTP $code fetching review ${review_id} comments" >&2; continue; }
  jq -r --arg rid "$review_id" '.[] |
    "COMMENT \($rid)-\(.id) resolved=\(.resolver != null) \(.path // ""):\(.position // .line // .original_line // "?") by \(.user.login)",
    (if .diff_hunk and .diff_hunk != "" then
      "  ```diff",
      (.diff_hunk | split("\n") | "  " + join("\n  ")),
      "  ```"
    else empty end),
    (.body | split("\n")[:3] | "  " + join("\n  ")),
    "---"' "$tmp2"
done
