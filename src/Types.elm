module Types exposing (..)

import Dict exposing (Dict)
import Json.Decode exposing (Value)
import Ports
import Time


type alias Model =
    { wallet : Maybe String
    , demoAddress : List String
    , status : Maybe Int
    , nftId : Maybe Ports.Key
    , err : Maybe String
    , idInput : String
    , startInput : String
    , endInput : String
    , containInput : String
    , idCheck : Maybe (Maybe String)
    , idInProg : Int
    , idWaiting : Bool
    , keys : List Ports.Key
    , vanity : List Ports.Vanity
    , view : View
    , mintSig : Maybe String
    , walletInUse : Bool
    , isMobile : Bool
    , count : Int
    , grinding : Bool
    , availability : Dict Int Bool
    , rpc : String
    , message : Maybe String
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
    | ViewFaq


type Msg
    = SelectWallet
    | MintNft (List Int)
    | FileCb Value
    | WalletCb String
    | AddrCb (List String)
    | AvailCb Int
    | IdCheckCb (Maybe String)
    | NftCb Ports.Key
    | Disconnect
    | Reset
    | SubmitId
    | MintCb String
    | MintErr
    | IdInputChange String
    | EndChange String
    | StartChange String
    | ContainChange String
    | SetView View
    | Generate
    | StopGrind
    | GrindCb { count : Int, keys : List Ports.Key }
    | UseKey Ports.Key
    | AccountCheckCb Int (Maybe Bool)
    | VanityGen
    | VanityCb { count : Int, keys : List Ports.Vanity }
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
