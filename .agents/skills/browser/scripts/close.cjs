// Gracefully close a background browser through its debug protocol so it
// flushes cookies/session state to the profile on disk before exiting.
// Used by scripts/stop.sh; falls back to signals if this fails.
const { connect } = require('./attach.cjs');

(async () => {
  const kind = process.argv[2];
  // recover:false — this script runs inside stop.sh; letting connect()
  // restart the browser from here would recurse (stop -> close -> restart
  // -> stop). If the session is leaked the graceful close fails and
  // stop.sh falls back to signals, as designed.
  const browser = await connect(kind, { recover: false });
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
