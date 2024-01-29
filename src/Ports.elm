port module Ports exposing (..)

import Json.Decode exposing (Value)


type alias Key =
    { pubkey : String
    , parts : List String
    , bytes : List Int
    , nft : Maybe { id : Int, register : String }
    }


type alias Vanity =
    { pubkey : String
    , bytes : List Int
    }



-- OUT


port log : String -> Cmd msg


port checkId : Int -> Cmd msg


port vanity : Value -> Cmd msg


port generatePow : () -> Cmd msg


port stopGrind : () -> Cmd msg


port openWalletMenu : () -> Cmd msg


port mintNft : List Int -> Cmd msg


port fileOut : Value -> Cmd msg



-- IN


port idExists : (Maybe String -> msg) -> Sub msg


port addrCb : (List String -> msg) -> Sub msg


port walletCb : (String -> msg) -> Sub msg


port startTimeCb : (Int -> msg) -> Sub msg


port mintCb : (String -> msg) -> Sub msg


port grindCb : ({ count : Int, keys : List Key } -> msg) -> Sub msg


port mintErr : (() -> msg) -> Sub msg


port nftCb : (Key -> msg) -> Sub msg


port vanityCb : ({ count : Int, keys : List Vanity } -> msg) -> Sub msg


port availabilityCb : (Int -> msg) -> Sub msg


port disconnect : (() -> msg) -> Sub msg
