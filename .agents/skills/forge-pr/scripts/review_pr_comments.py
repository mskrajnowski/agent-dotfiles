#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# List review comments on a PR, grouped by review, plus PR-level comments.
# This is the core loop for addressing feedback: read comments -> fix code ->
# commit -> force-push -> reply to each addressed comment with the commit SHA.

import argparse
import contextlib
import sys

try:
    import requests
except ModuleNotFoundError:
    # uv inline-dependency script: bare `python` skips uv's dependency resolution.
    sys.exit(
        "ERROR: missing 'requests' — run this as a uv script: "
        "./scripts/<name>.py or `uv run --script scripts/<name>.py`, "
        "not with bare python."
    )

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


def comment_position(comment: dict) -> object:
    """Where in the diff the comment anchors (position, line, or '?')."""
    return comment.get("position") or comment.get("line") or comment.get("original_line") or "?"


def main() -> None:
    parser = argparse.ArgumentParser(description="List a PR's review comments by review.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    args = parser.parse_args()

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.get(f"{BASE}/repos/{args.repo}/pulls/{args.index}/reviews", timeout=TIMEOUT)
    if resp.status_code != 200:
        fail(resp, "fetching reviews")
    for review in resp.json():
        print(
            f"REVIEW {review['id']} {review.get('state') or 'PENDING'} by {review['user']['login']}"
        )
        resp = session.get(
            f"{BASE}/repos/{args.repo}/pulls/{args.index}/reviews/{review['id']}/comments",
            timeout=TIMEOUT,
        )
        if resp.status_code != 200:
            print(
                f"WARN: HTTP {resp.status_code} fetching review {review['id']} comments",
                file=sys.stderr,
            )
            continue
        for comment in resp.json():
            resolved = "true" if comment.get("resolver") is not None else "false"
            print(
                f"COMMENT {review['id']}-{comment['id']} resolved={resolved} "
                f"{comment.get('path') or ''}:{comment_position(comment)} "
                f"by {comment['user']['login']}"
            )
            hunk = comment.get("diff_hunk")
            if hunk:
                print("  ```diff")
                print(indent(hunk))
                print("  ```")
            print(indent(comment.get("body") or ""))
            print("---")

    # PRs are issues on the forge: general (non-inline) comments live on the
    # issue endpoint — a common source of missed PR-level feedback.
    resp = session.get(f"{BASE}/repos/{args.repo}/issues/{args.index}/comments", timeout=TIMEOUT)
    if resp.status_code != 200:
        print(f"WARN: HTTP {resp.status_code} fetching PR-level comments", file=sys.stderr)
        return
    pr_comments = resp.json()
    if pr_comments:
        print("PR-LEVEL COMMENTS (no diff anchor):")
        for comment in pr_comments:
            print(
                f"COMMENT {comment['id']} by {comment['user']['login']} at {comment['created_at']}"
            )
            print(indent(comment.get("body") or ""))
            print("---")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
