#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Summarize a pull request in one call: status, description, and timeline.
# Prints: state, mergeability, head->base, change stats, total and
# unresolved review comment counts, requested reviewers, reviews,
# the PR description, and a compact event timeline.

import argparse
import contextlib
import re
import sys

import requests

FORGE_URL = "http://forge.local"
BASE = FORGE_URL + "/api/v1"
TIMEOUT = 30


def fail(resp: requests.Response, context: str = "") -> None:
    """Print 'ERROR: HTTP <code>[ (<context>)]' plus the API message; exit 1."""
    message = f"ERROR: HTTP {resp.status_code}"
    if context:
        message += f" ({context})"
    print(message, file=sys.stderr)
    with contextlib.suppress(ValueError, KeyError):
        print(resp.json()["message"], file=sys.stderr)
    sys.exit(1)


def indent(text: str, prefix: str = "  ") -> str:
    """Prefix every line of a multi-line string."""
    return "\n".join(prefix + line for line in text.split("\n"))


def format_timeline(entries: list[dict]) -> str:
    """Render timeline entries as compact one-line events."""
    lines = []
    for entry in entries:
        when = (entry.get("created_at") or "")[:16].replace("T", " ")
        who = (
            (entry.get("user") or {}).get("login")
            or (entry.get("poster") or {}).get("login")
            or "system"
        )
        typ = entry.get("type") or "?"
        line = f"  {when} {typ} {who}"
        if typ == "comment":
            body = re.sub(r"\n+", " ", entry.get("body") or "")[:100]
            line += " " + body
        lines.append(line)
    return "\n".join(lines)


def mergeable_line(pr: dict) -> str:
    mergeable = pr.get("mergeable")
    if mergeable is True:
        return "true"
    if mergeable is False:
        return (
            f"FALSE — conflicts with {pr['base']['ref']}: "
            "merge or rebase main into the branch and resolve"
        )
    return "unknown (forge is recomputing; retry)"


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize a PR in one call.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    args = parser.parse_args()
    base = f"{BASE}/repos/{args.repo}"

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.get(f"{base}/pulls/{args.index}", timeout=TIMEOUT)
    if resp.status_code != 200:
        fail(resp)
    pr = resp.json()

    resp = session.get(f"{base}/pulls/{args.index}/reviews", timeout=TIMEOUT)
    if resp.status_code != 200:
        fail(resp, "fetching reviews")
    reviews = resp.json()

    # Fetch all review comments (per review) to count unresolved ones.
    # A failing per-review fetch is skipped silently.
    comments = []
    for review in reviews:
        resp = session.get(
            f"{base}/pulls/{args.index}/reviews/{review['id']}/comments", timeout=TIMEOUT
        )
        if resp.status_code == 200:
            comments.extend(resp.json())

    # PRs are issues on the forge, so the issue timeline works with PR indexes.
    resp = session.get(
        f"{base}/issues/{args.index}/timeline", params={"limit": 50}, timeout=TIMEOUT
    )
    timeline = resp.json() if resp.status_code == 200 else []

    resolved = sum(1 for c in comments if c.get("resolver") is not None)
    total = len(comments)
    changed = pr.get("changed_files")
    requested = pr.get("requested_reviewers") or []
    names = ", ".join(user["login"] for user in requested) if requested else "-"

    print(f"PR #{pr['number']} [{pr['state']}] mergeable={mergeable_line(pr)}")
    print(f"  title: {pr['title']}")
    print(
        f"  head->base: {pr['head']['ref']} -> {pr['base']['ref']} | "
        f"changed: {changed if changed is not None else '?'} files, "
        f"+{pr.get('additions') or 0} -{pr.get('deletions') or 0}"
    )
    print(f"  review comments: {total} total, {total - resolved} unresolved, {resolved} resolved")
    print(f"  diff: {pr.get('diff_url') or '-'}")
    print(f"  requested reviewers: {names}")
    for review in reviews:
        print(
            f"  REVIEW {review['id']} {review.get('state') or 'PENDING'} "
            f"by {review['user']['login']}"
        )
    print()
    print("DESCRIPTION:")
    print(indent(pr.get("body") or ""))
    print()
    print("TIMELINE:")
    print(format_timeline(timeline))


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
