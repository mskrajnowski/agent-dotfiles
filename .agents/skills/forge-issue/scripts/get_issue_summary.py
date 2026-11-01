#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests"]
# ///
# Summarize an issue in one call: state, labels, description, timeline.

import argparse
import contextlib
import re
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


def format_timeline(entries: list[dict]) -> str:
    """Render timeline entries as compact one-line events."""
    lines = []
    for entry in entries:
        when = (entry.get("created_at") or "")[:16].replace("T", " ")
        who = (
            (entry.get("user") or {}).get("login")
            or (entry.get("poster") or {}).get("login")
            or "system"
        )
        typ = entry.get("type") or "?"
        line = f"  {when} {typ} {who}"
        if typ == "comment":
            body = re.sub(r"\n+", " ", entry.get("body") or "")[:100]
            line += " " + body
        lines.append(line)
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize an issue in one call.")
    parser.add_argument("repo", metavar="owner/repo")
    parser.add_argument("index", type=int)
    args = parser.parse_args()

    session = requests.Session()  # auth comes from ~/.netrc (or $NETRC)
    resp = session.get(f"{BASE}/repos/{args.repo}/issues/{args.index}", timeout=TIMEOUT)
    if resp.status_code != 200:
        fail(resp)
    issue = resp.json()

    resp = session.get(
        f"{BASE}/repos/{args.repo}/issues/{args.index}/timeline",
        params={"limit": 50},
        timeout=TIMEOUT,
    )
    timeline = resp.json() if resp.status_code == 200 else []

    labels = ", ".join(label["name"] for label in issue.get("labels") or []) or "-"
    print(f"ISSUE #{issue['number']} [{issue['state']}]")
    print(f"  title: {issue['title']}")
    print(f"  labels: {labels}")
    print()
    print("DESCRIPTION:")
    print(indent(issue.get("body") or ""))
    print()
    print("TIMELINE:")
    print(format_timeline(timeline))


if __name__ == "__main__":
    try:
        main()
    except requests.ConnectionError as exc:
        sys.exit(f"ERROR: cannot reach {FORGE_URL}: {exc}")
