#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Update a PR's title and/or body. Title/body only — state changes are
# the user's action.

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
    parser = argparse.ArgumentParser(description="Update a PR's title and/or body.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("--title")
    parser.add_argument("--body", metavar="body|-", help="new body; '-' reads it from stdin")
    args = parser.parse_args()
    if args.body == "-":
        args.body = sys.stdin.read().rstrip("\n")

    payload = {}
    if args.title:
        payload["title"] = args.title
    if args.body:
        payload["body"] = args.body
    if not payload:
        sys.exit("ERROR: nothing to update — pass --title and/or --body")

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.patch(
        f"{BASE}/repos/{args.repo}/pulls/{args.index}", json=payload, timeout=TIMEOUT
    )
    if resp.status_code not in (200, 201):
        fail(resp)
    print(f"PR #{args.index} updated")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
