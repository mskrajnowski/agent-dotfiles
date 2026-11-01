#!/usr/bin/env bash
# Summarize a pull request's status in one call.
# Usage: get_pr_status.sh <owner>/<repo> <pr-index>
# Prints: state, mergeability, head->base, commit count, unresolved
# review comment count, and title.
set -euo pipefail

repo=${1:?usage: get_pr_status.sh <owner>/<repo> <pr-index>}
index=${2:?missing PR index}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}
tmp=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp" "$tmp2"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$base")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/reviews")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching reviews" >&2; exit 1; }

jq -rn --slurpfile pr "$tmp" --slurpfile revs "$tmp2" \
  '($pr[0]) as $p | ($revs[0] | map(.comments_count // 0) | add // 0) as $cc |
  "PR #\($p.number) [\($p.state)] mergeable=\($p.mergeable // "?")",
  "  title: \($p.title)",
  "  head->base: \($p.head.ref) -> \($p.base.ref) | changed: \($p.changed_files // "?") files, +\($p.additions // 0) -\($p.deletions // 0)",
  "  review comments: \($cc) total",
  "  diff: \($p.diff_url // "-")",
  "  requested reviewers: \((if ($p.requested_reviewers // []) | length > 0 then ($p.requested_reviewers | map(.login) | join(", ")) else "-" end))",
  if ($revs[0] | length) > 0
  then ($revs[0] | map("  REVIEW \(.id) \(.state // "PENDING") by \(.user.login)") | join("\n"))
  else empty end'
