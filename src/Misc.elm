module Misc exposing (..)

import Base64
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Types exposing (..)


parseJWT : String -> Maybe ( String, Bool )
parseJWT =
    String.split "."
        >> List.drop 1
        >> List.head
        >> Maybe.andThen (Base64.decode >> Result.toMaybe)
        >> Maybe.andThen
            (List.map Char.fromCode
                >> String.fromList
                >> JD.decodeString
                    (JD.map2 Tuple.pair
                        (JD.field "sub" JD.string)
                        (JD.field "holder" JD.bool)
                    )
                >> Result.toMaybe
            )


decodeWsMsg : JD.Decoder WsMsg
decodeWsMsg =
    JD.oneOf
        [ JD.map4 PoolUpdateData
            (JD.field "pool_id" JD.string)
            (JD.field "lp_supply" JD.float)
            (JD.field "reserve" JD.float)
            (JD.field "price" JD.float)
            |> JD.map PoolUpdate
        , JD.field "sol_price" JD.float
            |> JD.map WsConnected
        , decodeHit
            |> JD.map PoolHit
        ]


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
        |> JDP.required "price" JD.float
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
