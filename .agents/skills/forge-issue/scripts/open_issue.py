#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Create an issue on the forge.
# Usage: open_issue.py <owner>/<repo> <title> [body|-]
# Prints: issue number and URL on success, error summary on failure.

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
    parser = argparse.ArgumentParser(description="Create an issue on the forge.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("title")
    args = parser.parse_args()
    args.body = sys.stdin.read().rstrip("\n")
    if not args.body:
        sys.exit("ERROR: empty body — pipe the issue body on stdin (required)")

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.post(
        f"{BASE}/repos/{args.repo}/issues",
        json={"title": args.title, "body": args.body},
        timeout=TIMEOUT,
    )
    if resp.status_code != 201:
        fail(resp)
    data = resp.json()
    print(f"Issue #{data['number']} opened: {data['html_url']}")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
