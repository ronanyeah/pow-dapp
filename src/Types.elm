module Types exposing (..)

import Dict exposing (Dict)
import Http
import Json.Decode as JD exposing (Value)
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
    , hits : Dict String PoolMintData
    , wsStatus : WsStatus
    , inventory : Maybe Inventory
    , viewUtility : ViewHolderAcc
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
    | ViewHolder


type ViewHolderAcc
    = ViewInventory
    | ViewUtility


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
    | HitCb (Result JD.Error PoolMintData)
    | WsConnect
    | WsDisconnect
    | WsDisconnected
    | WsConnectCb Bool
    | RefreshPool String
    | RefreshCb (Result Http.Error PoolMintData)
    | SignInCb ( String, String )
    | FetchInventory
    | ToggleUtility
    | ClearResults
    | Copy String


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
    , utilityAccess : Bool
    }


type alias PoolMintData =
    { name : String
    , reserve : Float
    , mint : String
    , lpMint : String
    , liquidityLocked : Bool
    , inPool : Float
    , top50 : Float
    , top20 : Float
    , top10 : Float
    , pool : String
    , price : Int
    , openTime : Int
    , symbol : String
    , mintSupply : Float
    , mintLocked : Bool
    , holders : Int
    }
