#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Request (or re-request) review from one or more users on a PR.
# Re-request after force-pushing fixes.

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
    parser = argparse.ArgumentParser(description="Request review on a PR.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("users", metavar="username", nargs="+")
    args = parser.parse_args()

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.post(
        f"{BASE}/repos/{args.repo}/pulls/{args.index}/requested_reviewers",
        json={"reviewers": args.users},
        timeout=TIMEOUT,
    )
    if resp.status_code not in (200, 201):
        fail(resp)
    print("Review requested from: " + " ".join(args.users))


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
