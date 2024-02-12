/* eslint-disable fp/no-loops, fp/no-mutation, fp/no-let */

import { Adapter } from "@solana/wallet-adapter-base";
import {
  PublicKey,
  SYSVAR_INSTRUCTIONS_PUBKEY,
  SystemProgram,
  Connection,
  ComputeBudgetProgram,
  TransactionInstruction,
  VersionedTransaction,
  Keypair,
  TransactionMessage,
} from "@solana/web3.js";
import { encode as bs58Encode } from "bs58";
import { mint as mintIx } from "./codegen/instructions";
import { Register } from "./codegen/accounts";
import {
  fetchMetadata,
  findMetadataPda,
  findMasterEditionPda,
  MPL_TOKEN_METADATA_PROGRAM_ID,
  findTokenRecordPda,
} from "@metaplex-foundation/mpl-token-metadata";
import {
  findAssociatedTokenPda,
  mplToolbox,
  SPL_ASSOCIATED_TOKEN_PROGRAM_ID,
  SPL_TOKEN_PROGRAM_ID,
} from "@metaplex-foundation/mpl-toolbox";
import { publicKey, isSome } from "@metaplex-foundation/umi";
import { createUmi } from "@metaplex-foundation/umi-bundle-defaults";

const PREFIX = "pow";

const RPC = (() => {
  /* eslint-disable no-undef */
  // @ts-ignore
  const RPC = __RPC_URL;
  /* eslint-enable no-undef */
  return new URL(RPC);
})();

const connection = new Connection(RPC.toString(), { commitment: "processed" });

const umi = createUmi(RPC.toString()).use(mplToolbox());

const PROGRAM_ID = new PublicKey("powCFRgLT5dRUdMXm4cBoajxM3S9gAcc54uvPrEwTcs");

const METAPLEX_RULES_PROGRAM = new PublicKey(
  "auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg"
);
const METAPLEX_DEFAULT_RULES = new PublicKey(
  "eBJLFYPxJmMGKuFwpDWkzxZeUrad92kZRC5BJLpzyT9"
);

const COLLECTION_MINT = new PublicKey(
  "PcoL2azniJHzRGjGMpj8PhxSwuFtb7QqxDVHC5xs7uL"
);
const COLLECTION_MASTER_EDITION = new PublicKey(
  findMasterEditionPda(umi, {
    mint: publicKey(COLLECTION_MINT),
  })[0]
);
const COLLECTION_METADATA = new PublicKey(
  findMetadataPda(umi, {
    mint: publicKey(COLLECTION_MINT),
  })[0]
);
const MINT_AUTHORITY = PublicKey.findProgramAddressSync(
  [toBuffer("CREATOR")],
  PROGRAM_ID
)[0];

const int32to8 = (n: number) => {
  const arr = Uint32Array.of(n);
  return new Uint8Array(arr.buffer, arr.byteOffset, arr.byteLength);
};

const buildMintIx = (wallet: PublicKey, mint: PublicKey, id: number) => {
  const [register] = PublicKey.findProgramAddressSync(
    [toBuffer("REGISTER"), int32to8(id)],
    PROGRAM_ID
  );
  const [assocAddr] = findAssociatedTokenPda(umi, {
    mint: publicKey(mint),
    owner: publicKey(wallet),
  });
  const [metaAddr] = findMetadataPda(umi, {
    mint: publicKey(mint),
  });
  const [masterAddr] = findMasterEditionPda(umi, {
    mint: publicKey(mint),
  });
  const [tokenRecord] = findTokenRecordPda(umi, {
    mint: publicKey(mint),
    token: assocAddr,
  });
  return mintIx(
    {
      signer: wallet,
      mintAuthority: MINT_AUTHORITY,
      mint: mint,
      mintMasterEdition: new PublicKey(masterAddr),
      mintMetadata: new PublicKey(metaAddr),
      mintAssoc: new PublicKey(assocAddr),
      systemProgram: SystemProgram.programId,
      tokenRecord: new PublicKey(tokenRecord),
      register,
      collectionMint: COLLECTION_MINT,
      collectionMetadata: COLLECTION_METADATA,
      collectionMasterEdition: COLLECTION_MASTER_EDITION,
      tokenMetadataProgram: new PublicKey(MPL_TOKEN_METADATA_PROGRAM_ID),
      sysvarIxs: SYSVAR_INSTRUCTIONS_PUBKEY,
      splAtaProgram: new PublicKey(SPL_ASSOCIATED_TOKEN_PROGRAM_ID),
      authorizationRulesProgram: METAPLEX_RULES_PROGRAM,
      tokenProgram: new PublicKey(SPL_TOKEN_PROGRAM_ID),
      ruleSet: METAPLEX_DEFAULT_RULES,
    },
    PROGRAM_ID
  );
};

async function readRegister(n: number): Promise<[PublicKey, Register | null]> {
  const register = findRegister(n);
  return [register, await Register.fetch(connection, register, PROGRAM_ID)];
}

function findRegister(n: number): PublicKey {
  const [register] = PublicKey.findProgramAddressSync(
    [toBuffer("REGISTER"), int32to8(n)],
    PROGRAM_ID
  );
  return register;
}

function parsePow(pk: PublicKey): { id: number | null; parts: string[] } {
  const id = extractMintId(pk);
  if (!id) {
    return { id: null, parts: [pk.toString()] };
  }
  const idStr = id.toString();

  const parts = [
    PREFIX,
    idStr,
    pk.toString().slice(PREFIX.length + idStr.length),
  ];
  return { id, parts };
}

function extractMintId(pk: PublicKey): number | null {
  const input = pk.toString();
  if (!input.startsWith(PREFIX)) {
    return null;
  }

  const s = input.slice(PREFIX.length);

  let digitStr = "";
  for (const c of s) {
    if (!isNaN(parseInt(c))) {
      digitStr += c;
    } else {
      break;
    }
  }

  if (digitStr.length === 0) {
    return null;
  }

  return parseInt(digitStr, 10);
}

async function fetchCollectionSize() {
  const [coll] = findMetadataPda(umi, { mint: publicKey(COLLECTION_MINT) });
  const acct = await fetchMetadata(umi, coll);
  return isSome(acct.collectionDetails)
    ? Number(acct.collectionDetails.value.size)
    : 0;
}

async function fetchRegisters() {
  const accts = await connection.getProgramAccounts(PROGRAM_ID);
  return accts.map((acct) => Register.decode(acct.account.data));
}

async function fetchTier(n: number) {
  const filters = [
    {
      memcmp: {
        offset: 8 + 4,
        bytes: bs58Encode(new Uint8Array([n])),
      },
    },
  ];
  const accts = await connection.getProgramAccounts(PROGRAM_ID, {
    filters: filters,
  });
  return accts.map((acct) => Register.decode(acct.account.data));
}

async function simulate(
  wallet: Adapter,
  ixs: TransactionInstruction[],
  signers?: Keypair[]
) {
  const latestBlockHash = await connection.getLatestBlockhash();
  const message = new TransactionMessage({
    payerKey: wallet.publicKey!,
    recentBlockhash: latestBlockHash.blockhash,
    instructions: [
      ComputeBudgetProgram.setComputeUnitLimit({ units: 500_000 }),
    ].concat(ixs),
  }).compileToV0Message();
  const tx = new VersionedTransaction(message);

  //(wallet as BaseSignerWalletAdapter)
  const signedTx = await (wallet as any).signTransaction(tx, { signers });
  const sim = await connection.simulateTransaction(signedTx);
  if (sim.value.err) {
    console.log(sim.value.logs);
    throw Error(sim.value.err.toString());
  }
  //console.log(sim.value.logs!.length === 0 ? sim.value : sim.value.logs);
  return "succeed";
}

async function launch(
  wallet: Adapter,
  ixs: TransactionInstruction[],
  signers?: Keypair[]
) {
  const latestBlockHash = await connection.getLatestBlockhash();
  const message = new TransactionMessage({
    payerKey: wallet.publicKey!,
    recentBlockhash: latestBlockHash.blockhash,
    instructions: [
      ComputeBudgetProgram.setComputeUnitLimit({ units: 500_000 }),
    ].concat(ixs),
  }).compileToV0Message();
  const tx = new VersionedTransaction(message);
  //}).compileToLegacyMessage();
  //const tx = new Transaction(message);

  return signers
    ? wallet.sendTransaction(tx, connection, { signers })
    : wallet.sendTransaction(tx, connection);
}

async function readKeypair(file: File): Promise<Keypair> {
  const arrayBuffer = await file.arrayBuffer();
  const content = new TextDecoder().decode(arrayBuffer);
  const parsed = JSON.parse(content);

  return Keypair.fromSecretKey(new Uint8Array(parsed));
}

function toBuffer(str: string) {
  return new TextEncoder().encode(str);
}

function createXXX(): [string, string, string] {
  const inputString = Keypair.generate().publicKey.toString();

  const midStart = Math.floor(Math.random() * (35 - 3 + 1)) + 3;

  const midEnd = midStart + (Math.floor(Math.random() * 3) + 2);

  const start = inputString.substring(0, midStart);
  const middle = "X".repeat(midEnd - midStart);
  const end = inputString.substring(midEnd);

  return [start, middle, end];
}

const randN = (min: number, max: number) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

function createPow(): [string, string, string] {
  const nums = "123456789";

  const pk = Keypair.generate().publicKey.toString();

  const max = 40; // 44
  const min = 40; // 32
  const maxLen = randN(min, max);

  const id = String(randN(1000, 10_000))
    .split("")
    .map((x) => (x === "0" ? String(randN(1, 9)) : x))
    .join("");

  let suffix = pk.slice(PREFIX.length + id.length, maxLen);

  if (nums.includes(suffix[0])) {
    const char = pk
      .split("")
      .reverse()
      .find((c) => !nums.includes(c));
    suffix = char + suffix.slice(1);
  }

  return [PREFIX, id, suffix];
}

export {
  launch,
  simulate,
  readKeypair,
  fetchRegisters,
  fetchCollectionSize,
  buildMintIx,
  connection,
  readRegister,
  findRegister,
  parsePow,
  RPC,
  fetchTier,
  createPow,
};
