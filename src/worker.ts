/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import "@solana/webcrypto-ed25519-polyfill";
import { getAddressFromPublicKey } from "solana-new";

interface Params {
  count: number;
  criteria: Criteria;
}

type Criteria =
  | null
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

onmessage = async (event) => {
  const params: Params = event.data;

  const isMatch = (() => {
    const criteria = params.criteria;
    if (!criteria) {
      //const regex = /^b[1-9]\d*/;
      const regex = /^pow[1-9]\d*/;
      return (addr: string) => regex.test(addr);
    } else if ("start" in criteria && "end" in criteria) {
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

  while (count < params.count) {
    try {
      const keypair = await crypto.subtle.generateKey("Ed25519", true, [
        "sign",
        "verify",
      ]);
      keys.push(keypair);
      count += 1;
    } catch (e) {
      console.error("Key generation failed:", e);
    }
  }

  for (const keypair of keys) {
    try {
      const addr = await getAddressFromPublicKey(keypair.publicKey);

      if (isMatch(addr)) {
        postMessage({ match: await exportBytes(keypair) });
      }
    } catch (e) {
      console.error("Address generation failed:", e);
    }
  }

  postMessage({ exit: params.count });
};

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
