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

onmessage = (event) =>
  (async () => {
    const params: Params = event.data;

    const isMatch = (() => {
      const criteria = params.criteria;
      if ("start" in criteria && "end" in criteria) {
        return (addr: string) =>
          addr.startsWith(criteria.start) && addr.endsWith(criteria.end);
      } else if ("start" in criteria) {
        return (addr: string) => addr.startsWith(criteria.start);
      } else {
        return (addr: string) => addr.endsWith(criteria.end);
      }
    })();

    let count = 0;
    const keys: CryptoKeyPair[] = [];

    // Parallelize key generation
    await Promise.all(Array.from({ length: params.count }, async () => {
      try {
        const keypair = await crypto.subtle.generateKey("Ed25519", true, [
          "sign",
          "verify",
        ]);
        keys.push(keypair);
      } catch (_e) {
        console.error("op1 fail");
      }
    }));

    // Batch key export and address check
    const keyExportPromises = keys.map(async (keypair) => {
      try {
        const addr = await getAddressFromPublicKey(keypair.publicKey);
        if (isMatch(addr)) {
          postMessage({ match: await exportBytes(keypair) });
        }
      } catch (_e) {
        console.error("op2 fail");
      }
    });

    await Promise.all(keyExportPromises);

    postMessage({ exit: params.count });
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
