---
name: browser
description: >-
  Automate a web browser (Chromium or Firefox) — start a browser in the
  background, drive it with Puppeteer, navigate/click/fill forms, extract
  page text, take screenshots for visual verification with the vision
  subagent. Use when the user asks to open or browse a website, automate
  or scrape a page, fill forms, log into a site, capture how a page
  renders, or check and verify page state.
---

# Browser automation

A browser runs **in the background** (headed on the desktop session, or
headless) and automation scripts **attach** to it. The browser process and
its profile live across script runs: cookies, logins and open tabs persist
until the browser is stopped. The profile is reused because it lives on
disk under `$HOME/.local/share/browser-skill/profiles/`.

Both browsers are driven with the **same Puppeteer API** (one script
dialect): Chromium attaches over CDP (port 9222), Firefox over WebDriver
BiDi (port 9223). Builds come from playwright's browser registry —
Chromium (Chrome for Testing) and Firefox — launched with
`--remote-debugging-port` (which serves BiDi on Firefox since CDP was
removed there).

## Quickstart

```sh
scripts/start.sh chromium                       # background browser (headed)
scripts/exec.sh examples/attach.cjs chromium https://example.com
scripts/stop.sh chromium
```

Use `firefox` the same way. Add `--headless` to `start.sh` when no visible
window is needed (headed mode needs the `desktop` skill's session; headless
does not).

## Writing automation scripts

Scripts are CommonJS (`script.cjs`) run by `scripts/exec.sh`, which keeps a
project-local npm environment in `/tmp/browser-skill` (puppeteer-core
installed on first use; add more dependencies with plain npm in that
directory) and exports `BROWSER_SKILL_DIR` so scripts can load the shared
attach helper:

```js
const { attach } = require(`${process.env.BROWSER_SKILL_DIR}/scripts/attach.cjs`);

const { page, detach } = await attach('chromium'); // or 'firefox'
await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
console.log(await page.title());

// state check before pixels — text first, vision second:
console.log(await page.evaluate(() => document.body.innerText));

await page.screenshot({ path: '/tmp/page.png' });
await detach(); // closes the connection only; the browser keeps running
```

End scripts with `detach()` — `browser.close()` would shut the browser
down on Firefox (and only disconnects on Chromium); `detach()` always does
the right thing. Puppeteer's auto-waiting locators (`page.locator('h1')`)
and ARIA selectors (`page.$('aria/Button Name')`) work on both engines;
a few niche features are unsupported over BiDi and throw
`UnsupportedOperation` on Firefox.

Puppeteer documentation:

- API reference: <https://pptr.dev/api> (e.g. `Page`, `Locator`,
  `Browser`, `CDPSession`)
- Guides — page interactions, browser management, network etc.:
  <https://pptr.dev/guides>
- What works over WebDriver BiDi (Firefox) and what throws
  `UnsupportedOperation`: <https://pptr.dev/webdriver-bidi>

## Verifying page state

1. **Text first** — `page.title()`, `page.url()`, and extracted text
   (`page.evaluate(() => document.body.innerText)`). Cheap and unambiguous.
2. **Then pixels** — `page.screenshot({ path: ... })` and inspect the PNG
   with the `vision` subagent. Screenshots capture the active page only;
   for the whole desktop (e.g. to confirm a window is visible on screen)
   use the `desktop` skill's `grim` screenshot instead.

## Scripts

- `scripts/start.sh [chromium|firefox] [--headless]` — start a background
  browser with its debug port and persistent profile. Idempotent: prints
  status if the browser is already up. Writes state to
  `~/.local/share/browser-skill/<browser>.env`.
- `scripts/stop.sh [chromium|firefox|all]` — stop background browser(s);
  closes gracefully through the debug protocol so cookies/session state
  flush to the profile.
- `scripts/exec.sh <script.cjs> [args...]` — run an automation script
  (prepares the npm work directory on first use).
- `scripts/attach.cjs` — helper used by scripts (see above).

## Environment

- Ports are fixed: 9222 (chromium) / 9223 (firefox). One background
  browser per engine — chromium and firefox can run side by side, but not
  two of the same kind.
- Browsers and their system dependencies come from the sandbox image
  (`/opt/ms-playwright`), provisioned by the agent-kit Dockerfile in the
  [dotfiles repo](http://forge.local/mskrajnowski/dotfiles) — see it for
  how browsers are installed and which versions are pinned.
- Reset a browser profile by stopping the browser and deleting
  `~/.local/share/browser-skill/profiles/<browser>`; cookies and logins are
  gone afterwards. Profile contents are sensitive — do not print or commit
  them.
