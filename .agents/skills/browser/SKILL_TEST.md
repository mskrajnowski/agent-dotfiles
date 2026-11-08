# SKILL_TEST

Regression scenarios for the browser skill. Run each after edits to
scripts or SKILL.md. Prerequisite: the sandbox image provides the browser
builds at /opt/ms-playwright (otherwise install them as the agent-kit
Dockerfile does).

## T1 — exec.sh prepares a project-local work directory

- Input: `rm -rf /tmp/browser-skill`, then `scripts/exec.sh` any example.
- Expected: first run creates /tmp/browser-skill and installs
  puppeteer-core there; scripts resolve it (no global node_modules
  involved). Subsequent runs reuse the directory without reinstalling.

## T2 — chromium background session, state persists across scripts

1. `scripts/start.sh chromium` — headed browser appears on the desktop
   (visible in a `grim` screenshot via the desktop skill).
2. `scripts/exec.sh examples/attach.cjs chromium https://example.com`
   prints url, title, body text, screenshot path.
3. Run a second script **without** a url argument (no navigation): it must
   report the example.com page opened in step 2 — pages persist across
   script runs.
4. Stop the browser (`scripts/stop.sh chromium`), start it again, and
   navigate to a page that sets a cookie; stop and start once more, then
   read the cookie from the profile — it must still be there (persistent
   profile).
5. `start.sh chromium` while already running prints status and exits 0.

## T3 — firefox background session (Puppeteer/BiDi)

1. `scripts/start.sh firefox`, then
   `scripts/exec.sh examples/attach.cjs firefox https://example.com`.
2. Re-run the same example without a url: it must report the page from
   step 1 (state persisted).
3. `scripts/stop.sh firefox` stops it; the profile directory is kept.

## T4 — headless

- `scripts/start.sh chromium --headless` must work without the desktop
  session running; automation scripts behave as in T2. Verify no window
  appears (no sway process needed) and the debug port answers.

## T5 — screenshot verification loop

- After a navigation script, inspect the screenshot with the `vision`
  subagent and confirm the rendered page matches the extracted text/title.
- Confirm the headed browser window is visible on the desktop via the
  desktop skill's `grim` screenshot (whole-desktop vs page-only view).

## T6 — error paths

- `exec.sh` a script attaching to a browser that was never started: clear
  error naming `scripts/start.sh`, not a stack trace about missing files.
- `stop.sh` with nothing running: "not running." and exit 0.
