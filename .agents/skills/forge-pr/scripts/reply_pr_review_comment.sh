#!/usr/bin/env bash
# Reply to a PR review comment.
# - Threaded comments (with a file anchor): the reply is posted on the same
#   review with the same path and positions — forgejo groups it into the
#   original thread. The body is plain text: the UI already shows the
#   original above the reply, so don't quote it.
# - Free-standing comments (no file anchor): the reply is posted as a
#   general PR comment quoting the original, since those get no thread UI.
#   The quote uses forgejo's own reply format (see forge/SKILL.md):
#   @<author> wrote in <permalink>: / blank line / blockquoted body / blank
#   line / reply text — the header must NOT be inside the blockquote.
#
# Reply BEFORE pushing commits — pushing changes the diff, and a reply
# posted against a changed diff can land as a separate thread.
#
# Usage: reply_pr_review_comment.sh <owner>/<repo> <index> <review-id> <comment-id> <text|->
#   text "-" reads the reply body from stdin.
# Prints: reply comment id on success.
set -euo pipefail

repo=${1:?usage: reply_pr_review_comment.sh <owner>/<repo> <index> <review-id> <comment-id> <text|->}
index=${2:?missing index}
review=${3:?missing review id}
cid=${4:?missing comment id}
text=${5:-}

if [[ $text == - ]]; then text=$(cat); fi
[[ -n $text ]] || { echo "ERROR: missing reply text" >&2; exit 1; }

base=http://forge.local/api/v1/repos/${repo}
tmp=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp" "$tmp2"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}/pulls/${index}/reviews/${review}/comments")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching review comments" >&2; exit 1; }

orig=$(jq -r --argjson id "$cid" 'map(select(.id == $id)) | .[0] // empty' "$tmp")
[[ -n $orig ]] || { echo "ERROR: comment $cid not found in review $review" >&2; exit 1; }

path=$(jq -r '.path // ""' <<<"$orig")

# Warn when the branch moved since the comment was made — replies posted
# against a changed diff may land as a separate thread.
code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/pulls/${index}")
head_sha=$(jq -r '.head.sha // ""' "$tmp2")
orig_commit=$(jq -r '.commit_id // .original_commit_id // ""' <<<"$orig")
if [[ -n $head_sha && -n $orig_commit && $head_sha != "$orig_commit" ]]; then
  echo "WARN: branch has moved since comment $cid — reply may not thread; reply before pushing next time" >&2
fi

if [[ -n $path ]]; then
  # Threaded reply: same review, same anchor, plain body.
  payload=$(jq -n --arg b "$text" --arg p "$path" \
    --argjson np "$(jq -r '.position // 0' <<<"$orig")" \
    --argjson op "$(jq -r '.original_position // 0' <<<"$orig")" \
    '{body: $b, path: $p, new_position: $np, old_position: $op}')
  code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" \
    -X POST "${base}/pulls/${index}/reviews/${review}/comments" \
    -H 'Content-Type: application/json' -d "$payload")
  if [[ $code == 200 || $code == 201 ]]; then
    jq -r '"Reply \(.id) posted in thread on \(.path):\(.position // .original_position // "?")"' "$tmp2"
  else
    echo "ERROR: HTTP $code" >&2
    jq -r '.message // empty' "$tmp2" >&2
    exit 1
  fi
else
  # Free-standing reply: quote the original as a PR comment, in forgejo's
  # native reply format (header outside the blockquote, blank lines between
  # header / quote / reply — see forge/references/API.md).
  author=$(jq -r '.user.login' <<<"$orig")
  body=$(jq -r '.body' <<<"$orig")
  url=http://forge.local/${repo}/pulls/${index}
  quoted=$(jq -rn --arg a "$author" --arg u "$url" --arg b "$body" --arg r "$text" \
    '"@" + $a + " wrote in " + $u + ":\n\n" +
    ($b | split("\n") | map("> " + .) | join("\n")) +
    "\n\n" + $r')
  code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" \
    -X POST "${base}/issues/${index}/comments" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg b "$quoted" '{body: $b}')")
  if [[ $code == 200 || $code == 201 ]]; then
    jq -r --arg c "$cid" '"Reply \(.id) posted as PR comment (quotes free-standing comment \($c))"' "$tmp2"
  else
    echo "ERROR: HTTP $code" >&2
    jq -r '.message // empty' "$tmp2" >&2
    exit 1
  fi
fi
