module Types exposing (..)

import Http
import Json.Decode exposing (Value)
import Ports
import Time


type alias Key =
    Ports.Key


type alias Model =
    { wallet : Maybe Wallet
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
    , isShort : Bool
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
    , hits : List Ports.Hit
    , wsStatus : WsStatus
    , inventory : Maybe Inventory
    }


type alias Flags =
    { screen : Screen
    , rpc : String
    , now : Int
    }


type View
    = ViewHome
    | ViewMint
    | ViewAvails
    | ViewGenerator
    | ViewHits


type Msg
    = SelectWallet
    | MintNft (List Int)
    | SignMessage
    | FileCb Value
    | WalletCb String
    | AddrCb (List String)
    | LoadKeypairCb (Maybe Ports.Key)
    | LoginCb (Result Http.Error String)
    | InventoryCb (Result Http.Error Inventory)
    | KeypairMintCheckCb (Result Http.Error (Maybe String))
    | IdMintCheckCb (Result Http.Error (Maybe String))
    | FindRegisterCb { id : Int, register : String }
    | Disconnect
    | Reset
    | SubmitId
    | MintCb String
    | WalletErr
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
    | HitCb Ports.Hit
    | WsConnect
    | WsDisconnected
    | WsConnectCb Bool
    | SignInCb ( String, String )
    | FetchInventory


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


type WsStatus
    = Standby
    | Connecting
    | Live


type alias Wallet =
    { address : String
    , token : Maybe String
    }


type alias Inventory =
    { t1 : Int
    , t2 : Int
    , t3 : Int
    , t4 : Int
    , t5 : Int
    , t6 : Int
    , t7 : Int
    , t8 : Int
    , t9 : Int
    , t10 : Int
    , z : Int
    , total : Int
    }
