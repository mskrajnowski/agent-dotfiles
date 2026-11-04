#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# List repositories visible to the authenticated user: one line per repo —
# full name, visibility, truncated description.

import contextlib
import sys

import requests

FORGE_URL = "http://forge.local"
BASE = FORGE_URL + "/api/v1"
TIMEOUT = 30
PAGE_SIZE = 50
DESC_WIDTH = 80


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
    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    repos: list[dict] = []
    page = 1
    while True:
        params = {"limit": PAGE_SIZE, "page": page, "private": True}
        resp = session.get(f"{BASE}/repos/search", params=params, timeout=TIMEOUT)
        if resp.status_code != 200:
            fail(resp, f"page {page}")
        data = resp.json().get("data", [])
        repos.extend(data)
        if len(data) < PAGE_SIZE:
            break
        page += 1

    for repo in repos:
        desc = (repo.get("description") or "").replace("\n", " ")
        if len(desc) > DESC_WIDTH:
            desc = desc[: DESC_WIDTH - 1] + "…"
        visibility = "private" if repo["private"] else "public"
        suffix = f" {desc}" if desc else ""
        print(f"{repo['full_name']} [{visibility}]{suffix}")


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
