#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# List the comments on an issue: per comment — id, author, timestamp, body.

import argparse
import contextlib
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


def main() -> None:
    parser = argparse.ArgumentParser(description="List the comments on an issue.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    args = parser.parse_args()

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.get(f"{BASE}/repos/{args.repo}/issues/{args.index}/comments", timeout=TIMEOUT)
    if resp.status_code != 200:
        fail(resp)
    for comment in resp.json():
        print(f"COMMENT {comment['id']} by {comment['user']['login']} at {comment['created_at']}")
        print(indent(comment.get("body") or ""))
        print("---")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
