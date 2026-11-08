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

Prefer **chromium** as the primary browser: it gets the full Puppeteer API
over CDP (reliable `newPage()`, raw CDP sessions, richer window control) and
avoids the Firefox BiDi quirks listed below. Use **firefox** for
compatibility checks — when a second engine opinion is useful, or when the
task is explicitly about Firefox-specific behavior.

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
attach helper. The preferred entry point is `withBrowser`, which runs a
callback and always releases the connection in a `finally` (on Firefox the
WebDriver BiDi session would otherwise outlive an errored run and block the
next attach — see "Firefox quirks" below):

```js
const { withBrowser } = require(`${process.env.BROWSER_SKILL_DIR}/scripts/attach.cjs`);

(async () => {
  await withBrowser('chromium', async ({ page, openTab }) => { // or 'firefox'
    await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
    console.log(await page.title());

    // state check before pixels — text first, vision second:
    console.log(await page.evaluate(() => document.body.innerText));

    // open a URL in a new tab (works on both engines; see Firefox quirks):
    const tab = await openTab('https://example.com/other');
    await tab.screenshot({ path: '/tmp/page.png' });
  });
})().catch((e) => { console.error(e); process.exit(1); });
```

The callback receives `{ kind, browser, page, openTab }`. `page` is a reused
tab, so consecutive scripts operate on the same session; cookies, logins and
open tabs persist until the browser is stopped. For scripts that need raw
access, low-level pieces are exported too: `attach(kind)` (returns
`{ kind, browser, page, detach }`), `connect(kind)`, `openTab(...)`, and
`stateFor(kind)`.

## Firefox quirks (WebDriver BiDi)

Firefox's remote agent has known single-session limitations. The skill
works around them; keep them in mind when writing scripts:

- **One BiDi session per instance, and it survives an abrupt disconnect.**
  A clean `detach()`/disconnect releases it, but a killed run (timeout,
  Ctrl-C, SIGKILL) leaves the session behind, and the next attach then
  fails with "Maximum number of active sessions". `connect()` detects that
  and transparently restarts the browser once (open tabs are lost).
  Upstream: [bug 1739363](https://bugzilla.mozilla.org/show_bug.cgi?id=1739363),
  [bug 1862018](https://bugzilla.mozilla.org/show_bug.cgi?id=1862018).
- **Never call `browser.newPage()` on Firefox** — it can hang forever
  (BiDi `browsingContext.create` waits for tab visibility). Use the
  `openTab(url)` helper: it uses `window.open()` from an existing page and
  finds the new tab by URL. Same family:
  [bug 1935104](https://bugzilla.mozilla.org/show_bug.cgi?id=1935104).
- **Don't match pages by `page.target()._targetId`** — that field is
  CDP-only and is `undefined` over BiDi. Match by URL instead (openTab
  does this for you).
- `browser.close()` shuts the browser down on Firefox (and only
  disconnects on Chromium); `withBrowser`/`detach()` always do the right
  thing.

## UI quirks

Visible browser chrome to expect — and to ignore when inspecting
screenshots:

- **Chromium: no automation infobar.** Chrome for Testing otherwise shows
  a permanent "Chrome for Testing v… is only for automated testing…"
  infobar below the address bar; `start.sh` launches it with
  `--disable-infobars`, a Chrome for Testing-only switch reintroduced for
  exactly this purpose
  ([chromium commit 5047fdc](https://github.com/chromium/chromium/commit/5047fdcf545bb979c1955c765dd361230c5fd728);
  branded Chrome removed the flag in 2019 and cannot use it).
- **Firefox: striped address bar + robot icon = remote control, not an
  error.** While the remote agent is listening (i.e. whenever a background
  Firefox is running), the URL bar gets an orange/red striped background
  and a robot icon appears; hovering it reads "Browser is under remote
  control by RemoteAgent". This is a deliberate, by-design indicator
  ([bug 1355890](https://bugzilla.mozilla.org/show_bug.cgi?id=1355890),
  [bug 1526364](https://bugzilla.mozilla.org/show_bug.cgi?id=1526364)) —
  don't confuse it with a broken profile.
- **Firefox popups.** Blocked popups or the tracking-protection shield
  panel can appear as small overlays after navigation/reload; dismiss with
  `page.keyboard.press('Escape')`.
- **WebGL is software-rendered in both engines** (no GPU in the sandbox):
  Chromium via SwiftShader (`--enable-unsafe-swiftshader`, passed by
  `start.sh` — required since Chrome 137 disabled the software fallback by
  default), Firefox via Mesa llvmpipe. OpenGL/WebGL sites work, but
  expect software-rendering performance and don't be surprised that
  `page.screenshot()` of a WebGL canvas can come out blank (compositor
  frame without `preserveDrawingBuffer`) — screenshot the desktop with
  `grim` instead to verify what the window actually shows.

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
