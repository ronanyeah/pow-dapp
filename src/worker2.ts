/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import * as ed from '@noble/ed25519';
import { sha512 } from '@noble/hashes/sha512';
import * as base58 from "bs58";
import { from } from 'rxjs';
import { filter } from 'rxjs/operators';

ed.etc.sha512Sync = (...m) => sha512(ed.etc.concatBytes(...m));

interface Params {
    count: number;
    criteria: Criteria;
}

type Criteria = {
    start?: string;
    end?: string;
};

onmessage = (event) => {
    const params: Params = event.data;
    const { count, criteria } = params;

    const isMatch = (address: string) => {
        return (!criteria.start || address.startsWith(criteria.start)) &&
            (!criteria.end || address.endsWith(criteria.end));
    };

    const privateKeys = Array.from({ length: count }, () => ed.utils.randomPrivateKey());
    from(privateKeys).pipe(
        filter(privateKey => {
            const publicKey = ed.getPublicKey(privateKey);
            const address = base58.encode(publicKey.slice(0, 32));
            return isMatch(address);
        }),
    ).subscribe({
        next: (privateKey) => {
            const publicKey = ed.getPublicKey(privateKey);
            const solanaKey = new Uint8Array(64);
            solanaKey.set(new Uint8Array(privateKey));
            solanaKey.set(new Uint8Array(publicKey).slice(0, 32), 32);
            postMessage({ match: solanaKey });
        },
        error: (e) => postMessage({ error: e.message }),
        complete: () => postMessage({ exit: params.count })
    });
};



