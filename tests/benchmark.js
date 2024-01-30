/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

const puppeteer = require("puppeteer");
const { getAddressFromPublicKey } = require("@solana/web3.js");
const fs = require("fs").promises;

(async () => {
  const browser = await puppeteer.launch({
    headless: "new",
  });
  const page = await browser.newPage();

  const workerCode = await fs.readFile("public/worker.js", "utf8");

  const workerStart = performance.now();
  const res = await page.evaluate(async (workerCode) => {
    const WORKER_COUNT = 1024;
    const TOTAL_COUNT = 250_000;
    const THREADS = 16;

    const params = { criteria: { start: "gg" }, count: WORKER_COUNT };
    const blob = new Blob([workerCode], { type: "application/javascript" });
    const workerUrl = URL.createObjectURL(blob);

    return new Promise((res, rej) => {
      let matches = [];
      let keysGenerated = 0;
      Array.from({ length: THREADS }, () => {
        const worker = new Worker(workerUrl);
        worker.onmessage = async (e) => {
          const data = e.data;
          if (data.exit) {
            keysGenerated += data.exit;
            if (keysGenerated >= TOTAL_COUNT) {
              return res({ keysGenerated, matches });
            } else {
              worker.postMessage(params);
            }
          }
          if (data.match) {
            return matches.push(Array.from(data.match));
          }
          if (data.error) {
            return rej(data.error);
          }
        };
        worker.onerror = (e) => {
          rej(e);
        };
        worker.postMessage(params);
      });
    });
  }, workerCode);

  const diff = performance.now() - workerStart;
  const kps = Math.round(res.keysGenerated / (diff / 1000));

  console.log(res.keysGenerated, "keys generated");
  console.log(kps, "kps");
  console.log(res.matches.length, "key(s) found");

  for (const keyBytes of res.matches) {
    console.log(
      await getAddressFromPublicKey(
        await crypto.subtle.importKey(
          "raw",
          keyBytes.slice(32),
          "Ed25519",
          true,
          ["verify"]
        )
      )
    );
  }

  return browser.close();
})().catch((err) => {
  console.error(err);
  return process.exit(1);
});
