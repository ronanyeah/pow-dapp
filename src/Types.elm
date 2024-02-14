module Types exposing (..)

import Http
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
    , idCheck :
        { inProg : Bool
        , id : Maybe Int
        , mint : Maybe (Maybe String)
        }
    , keypairCheck :
        { inProg : Bool
        , mint : Maybe (Maybe String)
        }
    , keys : List Ports.Key
    , view : View
    , viewGen : Maybe Bool
    , mintSig : Maybe String
    , walletInUse : Bool
    , isMobile : Bool
    , count : Int
    , grinding : Bool
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
    | LoadKeypairCb (Maybe Ports.Key)
    | KeypairMintCheckCb (Result Http.Error (Maybe String))
    | IdMintCheckCb (Result Http.Error (Maybe String))
    | FindRegisterCb { id : Int, register : String }
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
