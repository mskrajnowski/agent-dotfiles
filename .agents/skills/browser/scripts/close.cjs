// Gracefully close a background browser through its debug protocol so it
// flushes cookies/session state to the profile on disk before exiting.
// Used by scripts/stop.sh; falls back to signals if this fails.
const { connect } = require('./attach.cjs');

(async () => {
  const kind = process.argv[2];
  const browser = await connect(kind);
  if (kind === 'chromium') {
    // browser.close() on a CDP connection only disconnects; ask the browser
    // itself to shut down so it flushes state.
    const page = (await browser.pages())[0];
    const cdp = await page.createCDPSession();
    await cdp.send('Browser.close');
  } else {
    await browser.close(); // BiDi close shuts the browser down — intended here
  }
  console.log('graceful close sent');
})().catch((e) => { console.error('graceful close failed:', e.message); process.exit(1); });
