/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import "@solana/webcrypto-ed25519-polyfill";
import "@fontsource/bowlby-one-sc";
import "@fontsource-variable/montserrat";
import "@fontsource/bangers";
import "@fontsource/ibm-plex-mono";
import { ElmApp } from "./ports";
import {map, Observable, switchMap} from "rxjs";
import {SignKeyPair} from "tweetnacl";
import * as tweetnacl from "tweetnacl";
import base58 from "bs58";


const RPC = "foo";

// STUBS
const readRegister: any = {};
const findRegister: any = {};
const solConnect: any = {};
const decon: any = {};
const readKeypair: any = {};
const extractMintId: any = {};

const { Elm } = require("./Main.elm");

let vanityWorkers: Worker[] | null = null;

//const solConnect = new SolanaConnect();

(async () => {
  const app: ElmApp = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {
      screen: {
        width: window.innerWidth,
        height: window.innerHeight,
      },
      rpc: RPC,
    },
  });

  setInterval(() => {
    (async () => {
      createXXX().subscribe(addr => {
          app.ports.addrCb.send(addr);
      });
    })().catch(console.error);
  }, 400);

  //solConnect.onWalletChange((wallet) =>
  //(async () => {
  //if (wallet) {
  //app.ports.walletCb.send(wallet.publicKey!.toString());
  //} else {
  //app.ports.disconnect.send(null);
  //}
  //})().catch((e) => {
  //console.error(e);
  //})
  //);

  //app.ports.log.subscribe((txt: string) => console.log(txt));

  app.ports.checkId.subscribe((n) =>
    (async () => {
      const mint = await readRegister(n);
      app.ports.idExists.send(mint ? mint.toString() : null);
    })().catch(console.error)
  );

  app.ports.openWalletMenu.subscribe(() => {
    solConnect.openMenu();
  });

  app.ports.mintNft.subscribe((bytes) =>
    (async () => {
      const mintKeypair : SignKeyPair =  parseKeypair(new Uint8Array(bytes));
      const wallet = solConnect.getWallet();
      if (!wallet || !wallet.publicKey) {
        return;
      }

      const id = extractMintId(mintKeypair.publicKey);
      if (!id) {
        throw Error("Id not parsed");
      }

      console.log(id);

      //const ixns = [buildMintIx(wallet.publicKey, mintKeypair.publicKey, id)];
      //const sig = await launch(wallet, ixns, [mintKeypair]);
      //app.ports.mintCb.send(sig);
    })().catch((e) => {
      console.error(e);
      app.ports.mintErr.send(null);
    })
  );

  app.ports.fileOut.subscribe((file: File) =>
    (async () => {
      const kp = await readKeypair(file);
      const bytes: any[] = []; // Array.from(kp.secretKey);
      const nft = decon(kp.publicKey);
      const pubStr = kp.publicKey.toString();

      if (!nft.id) {
        return app.ports.nftCb.send({
          nft: null,
          pubkey: pubStr,
          bytes,
          parts: nft.parts,
        });
      }

      const register = findRegister(nft.id);

      return app.ports.nftCb.send({
        nft: { id: nft.id, register: register.toString() },
        pubkey: pubStr,
        parts: nft.parts,
        bytes,
      });
    })().catch((e) => {
      app.ports.availabilityCb.send(2);
      console.error(e);
    })
  );

  app.ports.stopGrind.subscribe(() => {
    if (vanityWorkers) {
      vanityWorkers.forEach((w) => w.terminate());
      vanityWorkers = null;
    }
  });

  app.ports.vanity.subscribe((obj) =>
    (async () => {
      if (!vanityWorkers) {
        const threads = navigator.hardwareConcurrency
          ? navigator.hardwareConcurrency / 2
          : 4;
        const ws = Array.from({ length: threads }, () => {
          const worker = new Worker("/rxworker.js", { type: "module" });
          worker.onmessage = async (e) => {
            if (e.data.exit) {
              app.ports.vanityCb.send({
                count: e.data.exit,
                keys: [],
              });
              worker.postMessage(obj);
            }
            if (e.data.error) {
              console.error(e.data.error);
            }
            if (e.data.count) {
              app.ports.vanityCb.send({
                count: e.data.count,
                keys: [],
              });
            }
            if (e.data.match) {
              app.ports.vanityCb.send({
                count: 0,
                keys: [
                    e.data.match,
                ],
              });
            }
          };
          worker.onerror = (e) => {
            console.error(e);
          };
          return worker;
        });
        vanityWorkers = ws;
      }
      app.ports.startTimeCb.send(Date.now());
      vanityWorkers.forEach((worker) => worker.postMessage(obj));
    })().catch((e) => {
      console.error(e);
    })
  );

  app.ports.generatePow.subscribe(() => {
    //
  });
})().catch((e) => {
  console.error(e);
});

function createXXX(): Observable<[string, string, string]> {
    return generateEd25519KeyPair$
        .pipe(
            map((keypair) => base58.encode(keypair.publicKey)),
            map(inputString => {

                const midStart = Math.floor(Math.random() * (35 - 3 + 1)) + 3;

                const midEnd = midStart + (Math.floor(Math.random() * 3) + 2);

                return [
                    inputString.substring(0, midStart),
                    "X".repeat(midEnd - midStart),
                    inputString.substring(midEnd)]
            })
        );
}


 function parseKeypair(solanaKeypair: Uint8Array): SignKeyPair {
  return tweetnacl.sign.keyPair.fromSecretKey(solanaKeypair);
}

const generateEd25519KeyPair$ : Observable<SignKeyPair>= new Observable<SignKeyPair>((subscriber) => {
  const keyPair: tweetnacl.SignKeyPair = tweetnacl.sign.keyPair();
  subscriber.next(keyPair);
  subscriber.complete();
});
