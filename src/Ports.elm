port module Ports exposing (..)

import Json.Decode exposing (Value)


type alias Key =
    { pubkey : String
    , parts : List String
    , bytes : List Int
    , nft :
        Maybe
            { id : Int
            , tier : Int
            , register : String
            }
    }



-- OUT


port log : String -> Cmd msg


port wsDisconnect : () -> Cmd msg


port wsConnect : String -> Cmd msg


port disconnectOut : () -> Cmd msg


port signIn : () -> Cmd msg


port findRegister : Int -> Cmd msg


port startGrind : Value -> Cmd msg


port stopGrind : () -> Cmd msg


port openWalletMenu : () -> Cmd msg


port mintNft : List Int -> Cmd msg


port fileOut : Value -> Cmd msg


port copy : String -> Cmd msg



-- IN


port findRegisterCb : ({ id : Int, register : String } -> msg) -> Sub msg


port addrCb : (List String -> msg) -> Sub msg


port signInCb : (( String, String ) -> msg) -> Sub msg


port walletCb : (String -> msg) -> Sub msg


port startTimeCb : (Int -> msg) -> Sub msg


port mintCb : (String -> msg) -> Sub msg


port grindCb : (Key -> msg) -> Sub msg


port countCb : (Int -> msg) -> Sub msg


port walletErr : (() -> msg) -> Sub msg


port loadKeypairCb : (Maybe Key -> msg) -> Sub msg


port disconnect : (() -> msg) -> Sub msg


port hitCb : (Value -> msg) -> Sub msg


port wsConnectCb : (Bool -> msg) -> Sub msg


port wsDisconnected : (() -> msg) -> Sub msg
