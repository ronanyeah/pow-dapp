module Misc exposing (..)

import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Types


decodeHit =
    JD.succeed Types.PoolMintData
        |> JDP.required "name"
            (JD.string
                |> JD.map (String.filter ((/=) '\u{0000}'))
            )
        |> JDP.required "reserve" JD.float
        |> JDP.required "mint" JD.string
        |> JDP.required "lpMint" JD.string
        |> JDP.required "liquidityLocked" JD.bool
        |> JDP.required "inPool" JD.float
        |> JDP.required "top50" JD.float
        |> JDP.required "top20" JD.float
        |> JDP.required "top10" JD.float
        |> JDP.required "pool" JD.string
        |> JDP.required "price" JD.int
        |> JDP.required "openTime" JD.int
        |> JDP.required "symbol" JD.string
        |> JDP.required "mintSupply" JD.float
        |> JDP.required "mintLocked" JD.bool
        |> JDP.required "holders" JD.int


haltedTiers =
    [ 5, 6, 7, 8 ]


completedTiers =
    [ 1, 2, 3 ]


u32_MAX : Int
u32_MAX =
    4294967295
