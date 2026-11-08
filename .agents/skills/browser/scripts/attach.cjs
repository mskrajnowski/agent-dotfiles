// Attach to a background browser started with scripts/start.sh.
//
// Preferred API — withBrowser runs a callback and always cleans up:
//
//   const { withBrowser } = require(`${process.env.BROWSER_SKILL_DIR}/scripts/attach.cjs`);
//   await withBrowser('chromium', async ({ browser, page, openTab }) => {
//     await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
//     const tab = await openTab('https://example.com'); // new tab, both engines
//     await tab.screenshot({ path: '/tmp/page.png' });
//   });
//
// The callback gets the connected browser, a reused page, and helpers.
// detach() runs in a finally, so thrown errors never leak the connection —
// and on Firefox the BiDi session, which otherwise outlives it (bug 1739363).
//
// Low-level pieces are also exported for scripts that need them:
//   attach(kind) -> { kind, browser, page, detach }
//   connect(kind), stateFor(kind), openTab(kind, browser, fromPage, url)
//
// Firefox over WebDriver BiDi has two known quirks this file works around:
// - One BiDi session per instance, and an abruptly killed client (SIGKILL,
//   aborted script run) leaves it behind; the next attach then fails with
//   "Maximum number of active sessions". connect() detects that and
//   transparently restarts the browser once.
//   https://bugzilla.mozilla.org/show_bug.cgi?id=1739363
//   https://bugzilla.mozilla.org/show_bug.cgi?id=1862018
// - browser.newPage() can hang forever (browsingContext.create waits for
//   tab visibility), so openTab() opens tabs with window.open() and finds
//   the new page by URL instead.
//   https://bugzilla.mozilla.org/show_bug.cgi?id=1935104

const fs = require('node:fs');
const path = require('node:path');

const DATA_DIR = path.join(process.env.HOME, '.local/share/browser-skill');
// Measured tab-open latency is ~30-450ms on both engines; 2s is a 5x
// margin. Heavy pages that need longer can pass { timeoutMs } explicitly.
const OPEN_TAB_TIMEOUT_MS = 2000;

function stateFor(kind) {
  const stateFile = path.join(DATA_DIR, `${kind}.env`);
  if (!fs.existsSync(stateFile)) {
    throw new Error(
      `no background ${kind}; start one with scripts/start.sh ${kind} ` +
      '(see the browser skill)',
    );
  }
  const state = {};
  for (const line of fs.readFileSync(stateFile, 'utf8').split('\n')) {
    const m = line.match(/^([A-Z_]+)=(.*)$/);
    if (m) state[m[1]] = m[2];
  }
  return state;
}

// Connect to the background browser of the given kind. Chromium uses CDP
// (browserURL), Firefox WebDriver BiDi (browserWSEndpoint + protocol) —
// the one place that knows the connect dialect for both.
async function connect(kind, { recover = true } = {}) {
  const puppeteer = require('puppeteer-core');
  const { PORT } = stateFor(kind);
  const options =
    kind === 'chromium'
      ? { browserURL: `http://127.0.0.1:${PORT}`, defaultViewport: null }
      : {
          browserWSEndpoint: `ws://127.0.0.1:${PORT}/session`,
          protocol: 'webDriverBiDi',
          defaultViewport: null,
        };
  try {
    return await puppeteer.connect(options);
  } catch (e) {
    // Firefox caps BiDi sessions at one per instance and a killed client
    // (timeout, Ctrl-C) leaves it behind. A clean disconnect does not leak,
    // so hitting the cap means a stale session — restarting clears it.
    if (recover && /maximum number of active sessions/i.test(e.message)) {
      console.error(
        `[browser-skill] ${kind}: stale WebDriver BiDi session (previous ` +
          'run was probably killed); restarting the browser once',
      );
      restart(kind);
      return connect(kind, { recover: false });
    }
    throw e;
  }
}

// stop.sh/start.sh close gracefully through the debug protocol (session
// state flushes to the profile) and block until the browser is ready.
function restart(kind) {
  const { spawnSync } = require('node:child_process');
  for (const script of ['stop.sh', 'start.sh']) {
    const res = spawnSync(path.join(__dirname, script), [kind], { stdio: 'inherit' });
    if (res.status !== 0) {
      throw new Error(`[browser-skill] could not restart ${kind} (${script} exited ${res.status})`);
    }
  }
}

async function attach(kind, { newPage = false } = {}) {
  const browser = await connect(kind);
  const pages = await browser.pages();
  const page = newPage || pages.length === 0 ? await browser.newPage() : pages[pages.length - 1];
  return { kind, browser, page, detach: () => browser.disconnect() };
}

// Open `url` in a new tab and return its Page. Works around the Firefox
// BiDi issues: newPage() there, window.open() + match-by-URL everywhere
// (Target._targetId is CDP-only and undefined over BiDi). Chromium waits
// for domcontentloaded, Firefox for the tab to commit the URL; slow pages
// can raise the deadline with { timeoutMs }.
async function openTab(kind, browser, fromPage, url, { timeoutMs = OPEN_TAB_TIMEOUT_MS } = {}) {
  if (kind !== 'firefox') {
    const tab = await browser.newPage();
    await tab.goto(url, { waitUntil: 'domcontentloaded', timeout: timeoutMs });
    return tab;
  }
  const base = url.split('#')[0];
  await fromPage.evaluate((u) => window.open(u), url);
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 300));
    for (const p of await browser.pages()) {
      if (p === fromPage) continue;
      const current = p.url();
      if (current === url || current.split('#')[0] === base) return p;
    }
  }
  throw new Error(`new tab for ${url} did not appear within ${timeoutMs}ms`);
}

// Run `fn` attached to the browser, with guaranteed cleanup. The callback
// receives { kind, browser, page, openTab } and may throw; the connection
// (and with it the Firefox BiDi session) is always released afterwards.
async function withBrowser(kind, fn) {
  const { browser, page, detach } = await attach(kind);
  try {
    return await fn({ kind, browser, page, openTab: (url, opts) => openTab(kind, browser, page, url, opts) });
  } finally {
    detach();
  }
}

module.exports = { attach, withBrowser, openTab, connect, stateFor };
