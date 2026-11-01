#!/usr/bin/env bash
# Summarize an issue in one call: state, description, and timeline.
# Usage: get_issue_summary.sh <owner>/<repo> <index>
# Prints: state, title, labels, the issue description, and a compact
# event timeline (comments, state changes, label events).
set -euo pipefail

repo=${1:?usage: get_issue_summary.sh <owner>/<repo> <index>}
index=${2:?missing issue index}

base=http://forge.local/api/v1/repos/${repo}/issues/${index}
tmp=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp" "$tmp2"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$base")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/timeline?limit=50")
[[ $code == 200 ]] || echo "[]" > "$tmp2"

jq -rn --slurpfile iss "$tmp" --slurpfile tl "$tmp2" '
  ($iss[0]) as $i | ($tl[0] // []) as $tl |
  "ISSUE #\($i.number) [\($i.state)]",
  "  title: \($i.title)",
  "  labels: \((if ($i.labels // []) | length > 0 then ($i.labels | map(.name) | join(", ")) else "-" end))",
  "",
  "DESCRIPTION:",
  ($i.body // "" | split("\n") | map("  " + .) | join("\n")),
  "",
  "TIMELINE:",
  ($tl | map(
    (.created_at // "") as $when |
    ((.user.login // .poster.login // "system")) as $who |
    (.type // "?") as $type |
    "  \($when[0:16] | sub("T"; " ")) \($type) \($who)" +
    (if $type == "comment" then " " + ((.body // "") | gsub("[\\n]+"; " ") | .[0:100]) else "" end)
  ) | join("\n"))
'
