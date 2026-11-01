#!/usr/bin/env bash
# Summarize a pull request's status in one call.
# Usage: get_pr_status.sh <owner>/<repo> <pr-index>
# Prints: state, mergeability, head->base, change stats, total and
# unresolved review comment counts, requested reviewers, and reviews.
set -euo pipefail

repo=${1:?usage: get_pr_status.sh <owner>/<repo> <pr-index>}
index=${2:?missing PR index}

base=http://forge.local/api/v1/repos/${repo}/pulls/${index}
tmp=$(mktemp)
tmp2=$(mktemp)
tmp3=$(mktemp)
trap 'rm -f "$tmp" "$tmp2" "$tmp3"' EXIT

code=$(curl --netrc -s -o "$tmp" -w "%{http_code}" "$base")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code" >&2; exit 1; }

code=$(curl --netrc -s -o "$tmp2" -w "%{http_code}" "${base}/reviews")
[[ $code == 200 ]] || { echo "ERROR: HTTP $code fetching reviews" >&2; exit 1; }

# Fetch all review comments (per review) to count unresolved ones.
echo "[]" > "$tmp3"
while read -r review_id; do
  code=$(curl --netrc -s -o "$tmp3.fetch" -w "%{http_code}" "${base}/reviews/${review_id}/comments")
  [[ $code == 200 ]] || continue
  jq -s '.[0] + .[1]' "$tmp3" "$tmp3.fetch" > "$tmp3.next" && mv "$tmp3.next" "$tmp3"
done < <(jq -r '.[].id' "$tmp2")

jq -rn --slurpfile pr "$tmp" --slurpfile revs "$tmp2" --slurpfile rc "$tmp3" \
  '($pr[0]) as $p | ($revs[0]) as $revs | ($rc[0]) as $comments |
  ($comments | map(select(.resolver != null)) | length) as $resolved |
  ($comments | length) as $cc |
  "PR #\($p.number) [\($p.state)] mergeable=\($p.mergeable // "?")",
  "  title: \($p.title)",
  "  head->base: \($p.head.ref) -> \($p.base.ref) | changed: \($p.changed_files // "?") files, +\($p.additions // 0) -\($p.deletions // 0)",
  "  review comments: \($cc) total, \($cc - $resolved) unresolved, \($resolved) resolved",
  "  diff: \($p.diff_url // "-")",
  "  requested reviewers: \((if ($p.requested_reviewers // []) | length > 0 then ($p.requested_reviewers | map(.login) | join(", ")) else "-" end))",
  if ($revs | length) > 0
  then ($revs | map("  REVIEW \(.id) \(.state // "PENDING") by \(.user.login)") | join("\n"))
  else empty end'
