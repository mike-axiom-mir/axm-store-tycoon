import { chromium } from 'playwright';
import fs from 'node:fs';

const url = process.env.AXM_GAME_URL || 'http://127.0.0.1:8060/index.html';
const out = process.env.AXM_SCREENSHOT || 'game/visual-evidence/store-start.png';
fs.mkdirSync(out.split('/').slice(0,-1).join('/') || '.', { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ['--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist']
});
const page = await browser.newPage({ viewport: { width: 1440, height: 810 }, deviceScaleFactor: 1 });
const consoleLines = [];
const fatal = [];
page.on('console', msg => {
  const line = `[${msg.type()}] ${msg.text()}`;
  consoleLines.push(line);
  if (msg.type() === 'error') fatal.push(line);
});
page.on('pageerror', err => fatal.push(`[pageerror] ${err.message}`));

await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
await page.waitForSelector('canvas', { timeout: 60_000 });
await page.waitForTimeout(10_000);

const canvas = await page.locator('canvas').first();
const box = await canvas.boundingBox();
if (!box || box.width < 640 || box.height < 360) {
  throw new Error(`Godot canvas missing or too small: ${JSON.stringify(box)}`);
}

const cdp = await page.context().newCDPSession(page);
const shot = await cdp.send('Page.captureScreenshot', {
  format: 'png',
  fromSurface: true,
  captureBeyondViewport: false
});
fs.writeFileSync(out, Buffer.from(shot.data, 'base64'));
fs.writeFileSync('game/visual-evidence/browser-console.txt', consoleLines.join('\n') + '\n');
const stat = fs.statSync(out);
if (stat.size < 20_000) throw new Error(`Screenshot suspiciously small (${stat.size} bytes)`);

const godotFatal = fatal.filter(line => !/AudioContext|favicon|autoplay/i.test(line));
if (godotFatal.length) {
  fs.writeFileSync('game/visual-evidence/fatal-browser-errors.txt', godotFatal.join('\n') + '\n');
  throw new Error(`Browser reported ${godotFatal.length} fatal console/page errors`);
}

console.log(`AXM visual gate PASS: ${out} (${stat.size} bytes, canvas ${Math.round(box.width)}x${Math.round(box.height)})`);
await browser.close();
