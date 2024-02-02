/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import "@solana/webcrypto-ed25519-polyfill";
import { getAddressFromPublicKey } from "@solana/web3.js";

interface Params {
  count: number;
  criteria: Criteria;
}

type Criteria =
  | {
      start: string;
    }
  | {
      end: string;
    }
  | {
      start: string;
      end: string;
    };

  type Counter = number;
  type KeyPair = CryptoKeyPair;

onmessage = (event: MessageEvent<any>) =>
  (async () => {
    const params: Params = event.data;

    const isMatch = (() => {
      const criteria = params.criteria;
      switch (true) {
        case "start" in criteria && "end" in criteria:
          return (addr: string) => addr.startsWith(criteria.start) && addr.endsWith(criteria.end);

        case "start" in criteria:
          return (addr: string) => addr.startsWith(criteria.start);

        default:
          return (addr: string) => addr.endsWith(criteria.end || ''); // Use empty string if end is not present
      }
    })();

    let count: Counter = 0;
    const keys: CryptoKeyPair[] = [];

    await Promise.all([
      (async () => {
        while (count < params.count) {
          try {
            const keypair: KeyPair = await crypto.subtle.generateKey("Ed25519", true, [
              "sign",
              "verify",
            ]);
            keys.push(keypair);
          } catch (_e: unknown) {
            console.error("op1 fail");
          }
          count += 1;
        }
      })(),
      (async () => {
        while (keys.length > 0 || count < params.count) {
          const keypair = keys.pop();
          if (keypair) {
            try {
              const addr = await getAddressFromPublicKey(keypair.publicKey);

              if (isMatch(addr)) {
                postMessage({ match: await exportBytes(keypair) });
              }
            } catch (_e: unknown) {
              console.error("op2 fail");
            }
          } else {
            await new Promise((resolve) => setTimeout(() => resolve(true), 0));
          }
        }
      })(),
    ]);
    postMessage({ exit: count });
  })().catch((e) => {
    postMessage({ error: e.message });
  });

async function exportBytes(keypair: CryptoKeyPair): Promise<Uint8Array> {
  const [exportedPublicKey, exportedPrivateKey] = await Promise.all([
    crypto.subtle.exportKey("raw", keypair.publicKey),
    crypto.subtle.exportKey("pkcs8", keypair.privateKey),
  ]);

  const solanaKey = new Uint8Array(64);
  solanaKey.set(new Uint8Array(exportedPrivateKey).slice(16));
  solanaKey.set(new Uint8Array(exportedPublicKey), 32);
  return solanaKey;
}