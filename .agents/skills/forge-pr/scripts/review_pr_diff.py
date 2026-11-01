#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Show a PR's diff or per-file change stats. Write large diffs to a file and
# summarize instead of reading them inline.

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
    parser = argparse.ArgumentParser(description="Show a PR's diff or change stats.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    parser.add_argument("mode", nargs="?", default="diff", choices=("diff", "stats"))
    args = parser.parse_args()

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    if args.mode == "stats":
        resp = session.get(
            f"{BASE}/repos/{args.repo}/pulls/{args.index}/files",
            params={"limit": 200},
            timeout=TIMEOUT,
        )
        if resp.status_code != 200:
            fail(resp, "fetching files")
        for file in resp.json():
            renamed = (
                f" (renamed from {file['previous_filename']})"
                if file.get("previous_filename")
                else ""
            )
            print(
                f"{file['filename']}  +{file.get('additions', 0)} "
                f"-{file.get('deletions', 0)}{renamed}"
            )
    else:
        # The diff endpoint returns plain text, not JSON.
        resp = session.get(f"{BASE}/repos/{args.repo}/pulls/{args.index}.diff", timeout=TIMEOUT)
        if resp.status_code != 200:
            fail(resp)
        sys.stdout.write(resp.text)


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
