/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import { asyncScheduler, filter, map, Observable, observeOn, range } from "rxjs";
import * as tweetnacl from "tweetnacl";
import { SignKeyPair } from "tweetnacl";
import * as base58 from "bs58";

interface Params {
    count: number;
    criteria: Criteria;
}

type Criteria =
    | {
    start?: string;
    end?: string;
};

onmessage = (event) => {
    const params: Params = event.data;

    const isMatch = (addr: string) => {
        const criteria = params.criteria;
        const startsWith = !criteria.start || addr.startsWith(criteria.start);
        const endsWith = !criteria.end || addr.endsWith(criteria.end);
        return startsWith && endsWith;
    };

    const generateEd25519KeyPair$ = new Observable<SignKeyPair>((subscriber) => {
        const keyPair: tweetnacl.SignKeyPair = tweetnacl.sign.keyPair();
        subscriber.next(keyPair);
        subscriber.complete();
    });

    const ed25519KeyPairs$ = generateEd25519KeyPair$.pipe(
        map((keyPair) => {
            const address = base58.encode(keyPair.publicKey.slice(0, 32));
            return isMatch(address) ? keyPair.secretKey : null;
        }),
        filter((value) => value !== null),
        observeOn(asyncScheduler)
    );

    range(0, params.count).pipe(source => ed25519KeyPairs$).subscribe(
        (value) => {
            if (value !== null) postMessage({ match: value });
        },
        (error) => {
            postMessage({ error: error.message });
        },
        () => {
            postMessage({ exit: params.count });
        }
    );
};
