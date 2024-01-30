// worker.ts

import "@solana/webcrypto-ed25519-polyfill";
import { getAddressFromPublicKey } from "@solana/web3.js";

interface CryptoKeyPair {
  publicKey: CryptoKey;
  privateKey: CryptoKey;
}

interface ExportedKeyPair {
  publicKey: Uint8Array;
  privateKey: Uint8Array;
}

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

onmessage = async (event) => {
  try {
    const params: Params = event.data;
    const isMatch = getMatchFunction(params.criteria);
    let count = 0;
    const keys: CryptoKeyPair[] = [];

    await Promise.all([
      generateKeyPairs(params.count, keys),
      processKeyPairs(params.count, keys, isMatch),
    ]);

    postMessage({ exit: count });
  } catch (e) {
    postMessage({ error: e.message });
  }
};

async function generateKeyPairs(count: number, keys: CryptoKeyPair[]) {
  while (keys.length < count) {
    try {
      const keypair = await crypto.subtle.generateKey("Ed25519", true, [
        "sign",
        "verify",
      ]);
      keys.push(keypair);
    } catch (error) {
      console.error("Key generation failed:", error.message);
    }
  }
}

async function processKeyPairs(count: number, keys: CryptoKeyPair[], isMatch: (addr: string) => boolean) {
  while (keys.length > 0 || count < params.count) {
    const keypair = keys.pop();
    if (keypair) {
      try {
        const addr = await getAddressFromPublicKey(keypair.publicKey);

        if (isMatch(addr)) {
          postMessage({ match: await exportBytes(keypair) });
        }
      } catch (error) {
        console.error("Operation 2 failed:", error.message);
      }
    } else {
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
  }
}

function getMatchFunction(criteria: Criteria): (addr: string) => boolean {
  if ("start" in criteria && "end" in criteria) {
    return (addr: string) => addr.startsWith(criteria.start) && addr.endsWith(criteria.end);
  } else if ("start" in criteria) {
    return (addr: string) => addr.startsWith(criteria.start);
  } else {
    return (addr: string) => addr.endsWith(criteria.end);
  }
}

async function exportBytes(keypair: CryptoKeyPair): Promise<ExportedKeyPair> {
  const [exportedPublicKey, exportedPrivateKey] = await Promise.all([
    crypto.subtle.exportKey("raw", keypair.publicKey),
    crypto.subtle.exportKey("pkcs8", keypair.privateKey),
  ]);

  const solanaKey = new Uint8Array(64);
  solanaKey.set(new Uint8Array(exportedPrivateKey).slice(16));
  solanaKey.set(new Uint8Array(exportedPublicKey), 32);

  return { publicKey: solanaKey.slice(32), privateKey: solanaKey.slice(0, 32) };
}
