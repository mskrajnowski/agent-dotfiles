#!/usr/bin/env bash
# Fetch reviews and review comments for a PR, flattened for agent use.
# Usage: review_pr_comments.sh <owner>/<repo> <index>
# Prints: review states, then each inline review comment: id, resolved status,
# file:line, author, and full body — followed by a PR-level comments section
# (issue-style comments on the PR index; PRs are issues in Forgejo).
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
    (.body | split("\n") | "  " + join("\n  ")),
    "---"' "$tmp2"
done

# PR-level (issue-style) comments — PRs are issues, so these live on the
# issue-comments endpoint, not under /reviews.
code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "http://forge.local/api/v1/repos/${repo}/issues/${index}/comments")
[[ $code == 200 ]] || { echo "WARN: HTTP $code fetching PR-level comments" >&2; exit 0; }
jq -r 'if length > 0 then
  "PR-LEVEL COMMENTS (no diff anchor):",
  (.[] | "COMMENT \(.id) by \(.user.login) at \(.created_at)",
    (.body | split("\n") | "  " + join("\n  ")),
    "---")
else empty end' "$tmp2"
