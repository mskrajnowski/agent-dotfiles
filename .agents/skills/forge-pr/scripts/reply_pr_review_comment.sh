#!/usr/bin/env bash
# Reply to a review comment by posting a quoted reply as a PR comment.
# (This forge's API has no threaded reply for review comments, so replies
# quote the original for context.)
# Usage: reply_pr_review_comment.sh <owner>/<repo> <pr-index> <review-id> <comment-id> <text|->
#   text "-" reads the reply body from stdin.
# Prints: new comment id on success.
set -euo pipefail

repo=${1:?usage: reply_pr_review_comment.sh <owner>/<repo> <pr-index> <review-id> <comment-id> <text|->}
index=${2:?missing PR index}
review=${3:?missing review id}
cid=${4:?missing comment id}
text=${5:-}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}/reviews/${review}/comments
tmp=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp" "$tmp2"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$base")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching review comments" >&2; exit 1; }

orig=$(jq -r --argjson id "$cid" 'map(select(.id == $id)) | .[0] // empty' "$tmp")
[[ -n $orig ]] || { echo "ERROR: comment $cid not found in review $review" >&2; exit 1; }

author=$(jq -r '.user.login' <<<"$orig")
path=$(jq -r '.path // "general"' <<<"$orig")
line=$(jq -r '.position // .line // .original_line // "?"' <<<"$orig")
body=$(jq -r '.body' <<<"$orig")

if [[ -z $text ]]; then echo "ERROR: missing reply text" >&2; exit 1; fi
if [[ $text == - ]]; then text=$(cat); fi

quoted=$(printf '> In reply to @%s (comment %s, `%s:%s`):\n> %s' \
  "$author" "$cid" "$path" "$line" "$(echo "$body" | sed 's/^/> /')" "$text")

code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" \
  -X POST "http://forge.local/api/v1/repos/${repo}/issues/${index}/comments" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg b "$quoted" '{body: $b}')")

if [[ $code == 201 ]]; then
  jq -r '"Reply posted as comment \(.id)"' "$tmp2"
else
  echo "ERROR: HTTP $code" >&2
  jq -r '.message // empty' "$tmp2" >&2
  exit 1
fi
