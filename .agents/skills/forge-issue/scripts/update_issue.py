#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Update an issue's title and/or body. Title/body only — state changes are
# the user's action.

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


def main() -> None:
    parser = argparse.ArgumentParser(description="Update an issue's title and/or body.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("--title")
    args = parser.parse_args()
    args.body = sys.stdin.read().rstrip("\n")

    payload = {}
    if args.title:
        payload["title"] = args.title
    if args.body:
        payload["body"] = args.body
    if not payload:
        sys.exit("ERROR: nothing to update — pipe the new body on stdin and/or pass --title")

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.patch(
        f"{BASE}/repos/{args.repo}/issues/{args.index}", json=payload, timeout=TIMEOUT
    )
    if resp.status_code not in (200, 201):
        fail(resp)
    print(f"Issue #{args.index} updated")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
