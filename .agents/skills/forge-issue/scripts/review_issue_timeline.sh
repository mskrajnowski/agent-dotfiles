#!/usr/bin/env bash
# Show the full event timeline of an issue (comments, state changes, labels).
# Usage: review_issue_timeline.sh <owner>/<repo> <issue-index>
# Prints: one line per event, chronological.
set -euo pipefail

repo=${1:?usage: review_issue_timeline.sh <owner>/<repo> <issue-index>}
index=${2:?missing issue index}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

api=http://forge.local/api/v1/repos/${repo}/issues/${index}/timeline
code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$api")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

jq -r 'def t: .[0:16] | sub("T"; " ");
.[] |
  (.created_at // "") as $when |
  ((.user.login // .poster.login // "system")) as $who |
  (.type // "?") as $type |
  if $type == "comment"
  then "COMMENT \($when) \($who): " + ((.body // "") | split("\n")[:2] | join(" ") | .[0:120])
  else "EVENT   \($when) \($who): \($type // "?")" end' "$tmp"
