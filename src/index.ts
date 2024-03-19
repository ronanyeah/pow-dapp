/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-mutating-methods, fp/no-let */

import { SolanaConnect } from "solana-connect";
import { Keypair, PublicKey } from "@solana/web3.js";
import "@fontsource/bowlby-one-sc";
import "@fontsource-variable/montserrat";
import "@fontsource/bangers";
import "@fontsource/ibm-plex-mono";
import { ElmApp } from "./ports";
import {
  signText,
  createPow,
  launch,
  buildMintIx,
  parsePow,
  findRegister,
  RPC,
} from "./web3";

// @ts-ignore
// eslint-disable-next-line no-undef
const WS_URL = __WS_URL;

const { Elm } = require("./Main.elm");

let keygenWorkers: Worker[] | null = null;

let ws: WebSocket | null = null;

const solConnect = new SolanaConnect();

(async () => {
  const app: ElmApp = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {
      screen: {
        width: window.innerWidth,
        height: window.innerHeight,
      },
      rpc: RPC.toString(),
      now: Date.now(),
      jwt: localStorage.getItem("JWT"),
    },
  });

  setInterval(() => {
    const addr = createPow();

    app.ports.addrCb.send(addr);
  }, 400);

  solConnect.onWalletChange((wallet) =>
    (async () => {
      if (wallet) {
        app.ports.walletCb.send(wallet.publicKey!.toString());
      } else {
        app.ports.disconnect.send(null);
      }
    })().catch((e) => {
      console.error(e);
    })
  );

  //solConnect.openMenu();

  app.ports.log.subscribe((txt: string) => console.log(txt));

  app.ports.saveJWT.subscribe((val) => {
    localStorage.setItem("JWT", val);
  });

  app.ports.disconnectOut.subscribe(() => {
    localStorage.removeItem("JWT");
    const wallet = solConnect.getWallet();
    if (wallet) {
      wallet.disconnect();
    }
  });

  app.ports.wsConnect.subscribe((token) =>
    (async () => {
      setupWS(app, token);
    })().catch((e) => {
      console.error(e);
    })
  );

  app.ports.signIn.subscribe(() =>
    (async () => {
      const wallet = solConnect.getWallet();
      if (wallet && "signMessage" in wallet) {
        const msg = "Time to POW: " + Date.now();
        const bts = await signText(msg, wallet);
        const hexSig = bts.reduce(
          (str, byte) => str + byte.toString(16).padStart(2, "0"),
          ""
        );
        app.ports.signInCb.send([msg, hexSig]);
      }
    })().catch((e) => {
      console.error(e);
      app.ports.walletErr.send(null);
    })
  );

  app.ports.findRegister.subscribe((id) =>
    (async () => {
      const register = await findRegister(id);
      app.ports.findRegisterCb.send({ id, register: register.toString() });
    })().catch((e) => {
      console.error(e);
    })
  );

  app.ports.openWalletMenu.subscribe(() => {
    solConnect.openMenu();
  });

  app.ports.copy.subscribe((val) => {
    navigator.clipboard.writeText(val);
  });

  app.ports.wsDisconnect.subscribe(() => {
    if (ws) {
      ws.close();
    }
  });

  app.ports.mintNft.subscribe((bytes) =>
    (async () => {
      const mintKeypair = Keypair.fromSecretKey(new Uint8Array(bytes));
      const wallet = solConnect.getWallet();

      if (!wallet || !wallet.publicKey) {
        return;
      }

      const pow = parsePow(mintKeypair.publicKey);
      if (!pow.id) {
        throw Error("Id not parsed");
      }

      const ixns = [
        buildMintIx(wallet.publicKey, mintKeypair.publicKey, pow.id),
      ];
      const sig = await launch(wallet, ixns, [mintKeypair]);
      app.ports.mintCb.send(sig);
    })().catch((e) => {
      console.error(e);
      app.ports.walletErr.send(null);
    })
  );

  app.ports.fileOut.subscribe((file: File) =>
    (async () => {
      const content = new TextDecoder().decode(await file.arrayBuffer());
      const bytes = JSON.parse(content);

      const kp = Keypair.fromSecretKey(new Uint8Array(bytes));
      const nft = parsePow(kp.publicKey);
      const pubStr = kp.publicKey.toString();

      if (!nft.id) {
        return app.ports.loadKeypairCb.send({
          nft: null,
          pubkey: pubStr,
          bytes,
          parts: nft.parts,
        });
      }

      const register = findRegister(nft.id);

      return app.ports.loadKeypairCb.send({
        nft: {
          id: nft.id,
          tier: nft.id.toString().length,
          register: register.toString(),
        },
        pubkey: pubStr,
        parts: nft.parts,
        bytes,
      });
    })().catch((e) => {
      app.ports.loadKeypairCb.send(null);
      console.error(e);
    })
  );

  app.ports.stopGrind.subscribe(() => {
    if (keygenWorkers) {
      keygenWorkers.forEach((w) => w.terminate());
      keygenWorkers = null;
    }
  });

  app.ports.startGrind.subscribe((obj) =>
    (async () => {
      if (!keygenWorkers) {
        const threads = navigator.hardwareConcurrency
          ? navigator.hardwareConcurrency / 2
          : 4;
        const ws = Array.from({ length: threads }, () => {
          const worker = new Worker("/worker.js", { type: "module" });
          worker.onmessage = async (e) => {
            if (e.data.exit) {
              app.ports.countCb.send(e.data.exit);

              // Restart the generation
              worker.postMessage(obj);
            }
            if (e.data.match) {
              const bytes = e.data.match;
              const pubkey = new PublicKey(bytes.slice(32));
              if (obj.criteria) {
                app.ports.grindCb.send({
                  pubkey: pubkey.toString(),
                  bytes: Array.from(e.data.match),
                  nft: null,
                  parts: [pubkey.toString()],
                });
              } else {
                const kp = e.data.match;

                const data = parsePow(pubkey);
                if (!data.id) {
                  throw Error("no bueno");
                }
                const register = findRegister(data.id);
                app.ports.grindCb.send({
                  pubkey: pubkey.toString(),
                  bytes: Array.from(kp),
                  nft: {
                    id: data.id,
                    tier: data.id.toString().length,
                    register: register.toString(),
                  },
                  parts: data.parts,
                });
              }
            }
          };
          worker.onerror = (e) => {
            console.error(e);
          };
          return worker;
        });
        keygenWorkers = ws;
      }
      app.ports.startTimeCb.send(Date.now());
      keygenWorkers.forEach((worker) => worker.postMessage(obj));
    })().catch((e) => {
      console.error(e);
    })
  );
})().catch((e) => {
  console.error(e);
});

function setupWS(app: ElmApp, token: string) {
  try {
    ws = new WebSocket(WS_URL);
  } catch (e) {
    console.error(e);
    return app.ports.wsConnectCb.send(false);
  }

  ws.addEventListener("open", () => {
    if (ws) {
      ws.send(token);
      app.ports.wsConnectCb.send(true);
    }
  });

  ws.addEventListener("error", (e) => {
    console.error("ws error:", e);
    if (ws) {
      ws.close();
    }
  });

  ws.addEventListener("close", async (e) => {
    console.warn("ws close:", e);
    ws = null;
    app.ports.wsDisconnected.send(null);
  });

  ws.addEventListener("message", (ev) =>
    (async () => {
      const hit = JSON.parse(ev.data.toString());
      app.ports.hitCb.send(hit);
    })().catch((e) => {
      console.error(e);
    })
  );
}
