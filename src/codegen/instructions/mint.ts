import { TransactionInstruction, PublicKey, AccountMeta } from "@solana/web3.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@coral-xyz/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface MintAccounts {
  signer: PublicKey
  mintAuthority: PublicKey
  register: PublicKey
  mint: PublicKey
  mintMetadata: PublicKey
  mintMasterEdition: PublicKey
  mintAssoc: PublicKey
  tokenRecord: PublicKey
  collectionMint: PublicKey
  collectionMetadata: PublicKey
  collectionMasterEdition: PublicKey
  ruleSet: PublicKey
  sysvarIxs: PublicKey
  authorizationRulesProgram: PublicKey
  tokenMetadataProgram: PublicKey
  systemProgram: PublicKey
  tokenProgram: PublicKey
  splAtaProgram: PublicKey
}

export function mint(
  accounts: MintAccounts,
  programId: PublicKey = PROGRAM_ID
) {
  const keys: Array<AccountMeta> = [
    { pubkey: accounts.signer, isSigner: true, isWritable: true },
    { pubkey: accounts.mintAuthority, isSigner: false, isWritable: false },
    { pubkey: accounts.register, isSigner: false, isWritable: true },
    { pubkey: accounts.mint, isSigner: true, isWritable: true },
    { pubkey: accounts.mintMetadata, isSigner: false, isWritable: true },
    { pubkey: accounts.mintMasterEdition, isSigner: false, isWritable: true },
    { pubkey: accounts.mintAssoc, isSigner: false, isWritable: true },
    { pubkey: accounts.tokenRecord, isSigner: false, isWritable: true },
    { pubkey: accounts.collectionMint, isSigner: false, isWritable: false },
    { pubkey: accounts.collectionMetadata, isSigner: false, isWritable: true },
    {
      pubkey: accounts.collectionMasterEdition,
      isSigner: false,
      isWritable: false,
    },
    { pubkey: accounts.ruleSet, isSigner: false, isWritable: false },
    { pubkey: accounts.sysvarIxs, isSigner: false, isWritable: false },
    {
      pubkey: accounts.authorizationRulesProgram,
      isSigner: false,
      isWritable: false,
    },
    {
      pubkey: accounts.tokenMetadataProgram,
      isSigner: false,
      isWritable: false,
    },
    { pubkey: accounts.systemProgram, isSigner: false, isWritable: false },
    { pubkey: accounts.tokenProgram, isSigner: false, isWritable: false },
    { pubkey: accounts.splAtaProgram, isSigner: false, isWritable: false },
  ]
  const identifier = Buffer.from([51, 57, 225, 47, 182, 146, 137, 166])
  const data = identifier
  const ix = new TransactionInstruction({ keys, programId, data })
  return ix
}
