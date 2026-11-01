#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Reply to a PR review comment. Threaded replies go on the same review with
# the same path/positions (forgejo groups by review + path + position — the
# API has no in_reply_to). Free-standing comments (no path) are answered as
# a general PR comment quoting the original in forgejo's reply format.
# Reply BEFORE pushing: pushing changes the diff and can split the thread.

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


def main() -> None:
    parser = argparse.ArgumentParser(description="Reply to a PR review comment.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("review", type=int, help="review id from review_pr_comments.py")
    parser.add_argument("comment", type=int, help="comment id from review_pr_comments.py")
    parser.add_argument("text", metavar="text|-", help="reply text; '-' reads it from stdin")
    args = parser.parse_args()
    if args.text == "-":
        args.text = sys.stdin.read().rstrip("\n")
    repo, index = args.repo, args.index

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.get(
        f"{BASE}/repos/{repo}/pulls/{index}/reviews/{args.review}/comments", timeout=TIMEOUT
    )
    if resp.status_code != 200:
        fail(resp, "fetching review comments")
    original = next((c for c in resp.json() if c["id"] == args.comment), None)
    if original is None:
        sys.exit(f"ERROR: comment {args.comment} not found in review {args.review}")
    path = original.get("path") or ""

    # Warn when the branch moved since the comment was made — replies posted
    # against a changed diff may land as a separate thread. This lookup is
    # best-effort: a failure here must not block the reply.
    resp = session.get(f"{BASE}/repos/{repo}/pulls/{index}", timeout=TIMEOUT)
    head_sha = resp.json().get("head", {}).get("sha", "") if resp.status_code == 200 else ""
    original_sha = original.get("commit_id") or original.get("original_commit_id") or ""
    if head_sha and original_sha and head_sha != original_sha:
        print(
            f"WARN: branch has moved since comment {args.comment} — "
            "reply may not thread; reply before pushing next time",
            file=sys.stderr,
        )

    if path:
        # Threaded reply: same review, same anchor, plain body (the UI already
        # shows the original above the reply, so don't quote it).
        resp = session.post(
            f"{BASE}/repos/{repo}/pulls/{index}/reviews/{args.review}/comments",
            json={
                "body": args.text,
                "path": path,
                "new_position": original.get("position") or 0,
                "old_position": original.get("original_position") or 0,
            },
            timeout=TIMEOUT,
        )
        if resp.status_code not in (200, 201):
            fail(resp)
        reply = resp.json()
        position = reply.get("position") or reply.get("original_position") or "?"
        print(f"Reply {reply['id']} posted in thread on {reply['path']}:{position}")
    else:
        # Free-standing: quote the original in forgejo's own reply format
        # (see forge/SKILL.md) since free-standing comments get no thread UI.
        author = original["user"]["login"]
        url = f"{FORGE_URL}/{repo}/pulls/{index}"
        quoted = "\n".join("> " + line for line in original["body"].split("\n"))
        resp = session.post(
            f"{BASE}/repos/{repo}/issues/{index}/comments",
            json={"body": f"@{author} wrote in {url}:\n\n{quoted}\n\n{args.text}"},
            timeout=TIMEOUT,
        )
        if resp.status_code not in (200, 201):
            fail(resp)
        print(
            f"Reply {resp.json()['id']} posted as PR comment "
            f"(quotes free-standing comment {args.comment})"
        )


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
