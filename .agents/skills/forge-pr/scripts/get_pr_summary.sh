#!/usr/bin/env bash
# Summarize a pull request in one call: status, description, and timeline.
# Usage: get_pr_summary.sh <owner>/<repo> <index>
# Prints: state, mergeability, head->base, change stats, total and
# unresolved review comment counts, requested reviewers, reviews,
# the PR description, and a compact event timeline.
set -euo pipefail

repo=${1:?usage: get_pr_summary.sh <owner>/<repo> <index>}
index=${2:?missing PR index}

base=http://forge.local/api/v1/repos/${repo}
tmp=$(mktemp)
tmp2=$(mktemp)
tmp3=$(mktemp)
tmp4=$(mktemp)
trap 'rm -f "$tmp" "$tmp2" "$tmp3" "$tmp4"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "${base}/pulls/${index}")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/pulls/${index}/reviews")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching reviews" >&2; exit 1; }

# Fetch all review comments (per review) to count unresolved ones.
echo "[]" > "$tmp3"
while read -r review_id; do
  code=$(curl --netrc -s -o "$tmp3.fetch" -w "%{http_code}" "${base}/pulls/${index}/reviews/${review_id}/comments")
  [[ $code == 200 ]] || continue
  jq -s '.[0] + .[1]' "$tmp3" "$tmp3.fetch" > "$tmp3.next" && mv "$tmp3.next" "$tmp3"
done < <(jq -r '.[].id' "$tmp2")

# PRs are issues on the forge, so the issue timeline works with PR indexes.
code=$(curl --netrc -s -o "$tmp4" -w "%{http_code}" "${base}/issues/${index}/timeline?limit=50")
[[ $code == 200 ]] || echo "[]" > "$tmp4"

jq -rn --slurpfile pr "$tmp" --slurpfile revs "$tmp2" --slurpfile rc "$tmp3" --slurpfile tl "$tmp4" '
  ($pr[0]) as $p | ($revs[0]) as $revs | ($rc[0]) as $comments | ($tl[0] // []) as $tl |
  ($comments | map(select(.resolver != null)) | length) as $resolved |
  ($comments | length) as $cc |
  ($p.mergeable) as $m |
  "PR #\($p.number) [\($p.state)] mergeable=\(if $m == true then "true" elif $m == false then "FALSE — conflicts with \($p.base.ref): merge or rebase main into the branch and resolve" else "unknown (forge is recomputing; retry)" end)",
  "  title: \($p.title)",
  "  head->base: \($p.head.ref) -> \($p.base.ref) | changed: \($p.changed_files // "?") files, +\($p.additions // 0) -\($p.deletions // 0)",
  "  review comments: \($cc) total, \($cc - $resolved) unresolved, \($resolved) resolved",
  "  diff: \($p.diff_url // "-")",
  "  requested reviewers: \((if ($p.requested_reviewers // []) | length > 0 then ($p.requested_reviewers | map(.login) | join(", ")) else "-" end))",
  if ($revs | length) > 0
  then ($revs | map("  REVIEW \(.id) \(.state // "PENDING") by \(.user.login)") | join("\n"))
  else empty end,
  "",
  "DESCRIPTION:",
  ($p.body // "" | split("\n") | map("  " + .) | join("\n")),
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
