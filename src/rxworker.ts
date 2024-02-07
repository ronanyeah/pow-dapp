/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import {asyncScheduler, filter, map, Observable, observeOn, range} from "rxjs";
import * as tweetnacl from "tweetnacl";
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

    const generateEd25519KeyPair$ = new Observable((subscriber) => {
        const keyPair: tweetnacl.SignKeyPair = tweetnacl.sign.keyPair();
        const address = base58.encode(keyPair.publicKey.slice(0, 32));
        return isMatch(address) ? subscriber.next({
                pubkey: address,
                bytes: Array.from(keyPair.secretKey)
            }
        ) : subscriber.complete();
    });

    range(0, params.count)
        .pipe(source =>
                generateEd25519KeyPair$
            , observeOn(asyncScheduler))
        .subscribe(
            (value) => {
                postMessage({match: value});
            },
            (error) => {
                postMessage({error: error.message});
            },
            () => {
                postMessage({exit: params.count});
            }
        );
};
