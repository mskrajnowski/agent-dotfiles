// Attach to a background browser (same script works for both engines —
// that's the point of the single Puppeteer dialect), open a page, print
// state, screenshot.
// Usage: exec.sh attach.cjs <chromium|firefox> [url]
const { withBrowser } = require(`${process.env.BROWSER_SKILL_DIR}/scripts/attach.cjs`);

(async () => {
  const kind = process.argv[2];
  if (kind !== 'chromium' && kind !== 'firefox') {
    console.error('usage: attach.cjs <chromium|firefox> [url]');
    process.exit(2);
  }

  await withBrowser(kind, async ({ page }) => {
    const url = process.argv[3];
    if (url) await page.goto(url, { timeout: 30000, waitUntil: 'domcontentloaded' });

    console.log('engine:', kind);
    console.log('url:', page.url());
    console.log('title:', await page.title());
    // Text-first state check.
    console.log('--- body text (first 500 chars) ---');
    console.log((await page.evaluate(() => document.body.innerText)).slice(0, 500));

    const shot = process.env.BROWSER_SKILL_SHOT || '/tmp/browser-screenshot.png';
    await page.screenshot({ path: shot });
    console.log('screenshot:', shot);
  });
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
