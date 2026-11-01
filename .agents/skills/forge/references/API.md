# Forgejo API quirks

Hard-won quirks of the current API. The forge-pr/forge-issue scripts already encode most of these — read this when calling the API directly or writing new forge scripts. Verify against the live instance (`GET /api/v1/version` reports the running version) if something misbehaves.

## Field names and shapes

- **PRs are issues:** issue endpoints work with PR indexes — `GET/POST /issues/{index}/comments`, `GET /issues/{index}/timeline`, and issue state changes all apply to PRs.
- **Review comment fields differ from issue comments:** author is `.user.login` (`.poster.login` is used by issue comments), line is `.position`, "resolved" is derived from `.resolver != null` (no `.resolved` boolean), and the anchor commit is `.commit_id` — `original_commit_id` is empty on this instance.
- **`GET /pulls/{index}` has no commit counts** (`commits: null`) — use `changed_files`, `additions`, `deletions` for change stats.

## Silently ignored parameters

- **`in_reply_to` and `commit_id` are silently ignored** by `POST /pulls/{index}/reviews/{id}/comments` — replies inherit the review's commit anchor and there is no way to re-anchor a reply to another commit. Threaded replies must post a comment on the same review at the same path + position (the UI groups those into one thread); reply before pushing, because pushed changes can detach replies into separate threads even with identical stored anchors.

## Endpoint gaps

- **Swagger can overstate the API:** `GET /pulls/{index}/requested_reviewers` is documented but returns 404; the `POST` variant works and returns `201` with an empty array.
- **Timeline events** (`GET /issues/{index}/timeline?limit=50`) include `comment`, `close`, `pull_push`, `review`, `review_request`, and `change_title` events.

## Discovery

- The full OpenAPI schema is at `http://forge.local/swagger.v1.json` — fetch it and search for the operation you need rather than guessing.
