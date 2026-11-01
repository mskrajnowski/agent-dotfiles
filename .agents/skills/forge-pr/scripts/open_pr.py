#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Open a pull request. The head branch must exist on the remote first
# (`git push -u origin <head>`); prints the PR number and URL.

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
    parser = argparse.ArgumentParser(description="Open a pull request.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("head")
    parser.add_argument("base")
    parser.add_argument("title")
    parser.add_argument(
        "body",
        nargs="?",
        default="",
        metavar="body|-",
        help="PR description; '-' reads it from stdin",
    )
    args = parser.parse_args()
    if args.body == "-":
        args.body = sys.stdin.read().rstrip("\n")

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.post(
        f"{BASE}/repos/{args.repo}/pulls",
        json={"head": args.head, "base": args.base, "title": args.title, "body": args.body},
        timeout=TIMEOUT,
    )
    if resp.status_code != 201:
        fail(resp)
    data = resp.json()
    print(f"PR #{data['number']} opened: {data['html_url']}")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
