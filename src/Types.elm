module Types exposing (..)

import Dict exposing (Dict)
import Json.Decode exposing (Value)
import Ports
import Time


type alias Key =
    Ports.Key


type alias Model =
    { wallet : Maybe String
    , demoAddress : List String
    , loadedKeypair : Maybe Ports.Key
    , err : Maybe String
    , idInput : String
    , startInput : String
    , endInput : String
    , containInput : String
    , idCheck : Maybe (Maybe String)
    , idInProg : Int
    , idWaiting : Bool
    , keys : List Ports.Key
    , view : View
    , viewGen : Maybe Bool
    , mintSig : Maybe String
    , walletInUse : Bool
    , isMobile : Bool
    , count : Int
    , grinding : Bool
    , nftExists : Dict Int Bool
    , rpc : String
    , grindMessage : Maybe String
    , keypairMessage : Maybe String
    , searchMessage : Maybe String
    , match : Match
    , screen : Screen
    , startTime : Int
    , now : Int
    }


type alias Flags =
    { screen : Screen
    , rpc : String
    }


type View
    = ViewHome
    | ViewMint
    | ViewAvails
    | ViewGenerator


type Msg
    = SelectWallet
    | MintNft (List Int)
    | FileCb Value
    | WalletCb String
    | AddrCb (List String)
    | IdCheckCb (Maybe String)
    | LoadKeypairCb (Maybe Ports.Key)
    | Disconnect
    | Reset
    | SubmitId
    | MintCb String
    | MintErr
    | IdInputChange String
    | EndChange String
    | StartChange String
    | SetView View
    | CountCb Int
    | StopGrind
    | GrindCb Ports.Key
    | AccountCheckCb Int (Maybe Bool)
    | PowGen
    | SelectNft Ports.Key
    | VanityGen
    | SetViewGen Bool
    | GenSelect Match
    | StartTimeCb Int
    | Tick Time.Posix


type alias Screen =
    { width : Int
    , height : Int
    }


type Match
    = MatchStart
    | MatchEnd
    | MatchBoth


type MintStatus
    = MintedOut
    | InProgress
    | Closed
