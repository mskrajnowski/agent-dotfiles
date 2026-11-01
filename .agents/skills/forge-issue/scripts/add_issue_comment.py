#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Add a comment to an issue; prints the new comment id.

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
    parser = argparse.ArgumentParser(description="Add a comment to an issue.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("text", metavar="text|-", help="comment text; '-' reads it from stdin")
    args = parser.parse_args()
    if args.text == "-":
        args.text = sys.stdin.read().rstrip("\n")
    if not args.text:
        sys.exit("ERROR: empty comment text")

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.post(
        f"{BASE}/repos/{args.repo}/issues/{args.index}/comments",
        json={"body": args.text},
        timeout=TIMEOUT,
    )
    if resp.status_code != 201:
        fail(resp)
    print(f"Comment {resp.json()['id']} added")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
