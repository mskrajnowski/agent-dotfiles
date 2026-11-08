// Attach to a background browser started with scripts/start.sh.
//
//   const { attach } = require(`${process.env.BROWSER_SKILL_DIR}/scripts/attach.cjs`);
//   const { browser, page, detach } = await attach('chromium'); // or 'firefox'
//   ... automate ...
//   await detach(); // closes the connection only; the browser keeps running
//
// Both engines are driven with puppeteer: Chromium over CDP, Firefox over
// WebDriver BiDi. `attach` reuses an already-open page when one exists, so
// consecutive scripts operate on the same session. Pass { newPage: true }
// for a fresh tab instead. Always end with `detach()`, never `close()` —
// on Firefox the latter shuts the browser down.

const fs = require('node:fs');
const path = require('node:path');

const DATA_DIR = path.join(process.env.HOME, '.local/share/browser-skill');

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
async function connect(kind) {
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
  return puppeteer.connect(options);
}

async function attach(kind, { newPage = false } = {}) {
  const browser = await connect(kind);
  const pages = await browser.pages();
  const page = newPage || pages.length === 0 ? await browser.newPage() : pages[pages.length - 1];
  return { kind, browser, page, detach: () => browser.disconnect() };
}

module.exports = { attach, connect, stateFor };
