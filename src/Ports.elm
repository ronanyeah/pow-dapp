port module Ports exposing (..)

import Json.Decode exposing (Value)


type alias Key =
    { pubkey : String
    , parts : List String
    , bytes : List Int
    , nft :
        Maybe
            { id : Int
            , register : String
            , mint : Maybe String
            }
    }



-- OUT


port log : String -> Cmd msg


port checkId : Int -> Cmd msg


port startGrind : Value -> Cmd msg


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


port grindCb : (Key -> msg) -> Sub msg


port countCb : (Int -> msg) -> Sub msg


port mintErr : (() -> msg) -> Sub msg


port loadKeypairCb : (Maybe Key -> msg) -> Sub msg


port disconnect : (() -> msg) -> Sub msg
