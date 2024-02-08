import { PublicKey, Connection } from "@solana/web3.js"
import BN from "bn.js" // eslint-disable-line @typescript-eslint/no-unused-vars
import * as borsh from "@coral-xyz/borsh" // eslint-disable-line @typescript-eslint/no-unused-vars
import { PROGRAM_ID } from "../programId"

export interface RegisterFields {
  id: number
  tier: number
  mint: PublicKey
}

export interface RegisterJSON {
  id: number
  tier: number
  mint: string
}

export class Register {
  readonly id: number
  readonly tier: number
  readonly mint: PublicKey

  static readonly discriminator = Buffer.from([
    134, 173, 244, 36, 162, 38, 90, 249,
  ])

  static readonly layout = borsh.struct([
    borsh.u32("id"),
    borsh.u8("tier"),
    borsh.publicKey("mint"),
  ])

  constructor(fields: RegisterFields) {
    this.id = fields.id
    this.tier = fields.tier
    this.mint = fields.mint
  }

  static async fetch(
    c: Connection,
    address: PublicKey,
    programId: PublicKey = PROGRAM_ID
  ): Promise<Register | null> {
    const info = await c.getAccountInfo(address)

    if (info === null) {
      return null
    }
    if (!info.owner.equals(programId)) {
      throw new Error("account doesn't belong to this program")
    }

    return this.decode(info.data)
  }

  static async fetchMultiple(
    c: Connection,
    addresses: PublicKey[],
    programId: PublicKey = PROGRAM_ID
  ): Promise<Array<Register | null>> {
    const infos = await c.getMultipleAccountsInfo(addresses)

    return infos.map((info) => {
      if (info === null) {
        return null
      }
      if (!info.owner.equals(programId)) {
        throw new Error("account doesn't belong to this program")
      }

      return this.decode(info.data)
    })
  }

  static decode(data: Buffer): Register {
    if (!data.slice(0, 8).equals(Register.discriminator)) {
      throw new Error("invalid account discriminator")
    }

    const dec = Register.layout.decode(data.slice(8))

    return new Register({
      id: dec.id,
      tier: dec.tier,
      mint: dec.mint,
    })
  }

  toJSON(): RegisterJSON {
    return {
      id: this.id,
      tier: this.tier,
      mint: this.mint.toString(),
    }
  }

  static fromJSON(obj: RegisterJSON): Register {
    return new Register({
      id: obj.id,
      tier: obj.tier,
      mint: new PublicKey(obj.mint),
    })
  }
}
