module Main exposing (main)

import Browser
import Ports
import Time
import Types exposing (..)
import Update exposing (update)
import View exposing (view)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { wallet = Nothing
      , keypairMessage = Nothing
      , err = Nothing
      , loadedKeypair = Nothing
      , isMobile = flags.screen.width < 1024 --|| flags.screen.height < 632
      , screen = flags.screen
      , demoAddress = []
      , keys = []
      , keypairCheck =
            { inProg = False
            , mint = Nothing
            }
      , idInput = ""
      , startInput = ""
      , endInput = ""
      , containInput = ""
      , idCheck =
            { inProg = False
            , id = Nothing
            , mint = Nothing
            }
      , view = ViewHome
      , viewGen = Nothing
      , mintSig = Nothing
      , walletInUse = False
      , count = 0
      , grinding = False
      , rpc = flags.rpc
      , grindMessage = Nothing
      , searchMessage = Nothing
      , match = MatchStart
      , startTime = 0

      --, now = Time.millisToPosix 0
      , now = 0
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.walletCb WalletCb
        , Ports.disconnect (always Disconnect)
        , Ports.loadKeypairCb LoadKeypairCb
        , Ports.findRegisterCb FindRegisterCb
        , Ports.addrCb AddrCb
        , Ports.mintCb MintCb
        , Ports.grindCb GrindCb
        , Ports.countCb CountCb
        , Ports.startTimeCb StartTimeCb
        , Ports.mintErr (always MintErr)
        , if model.grinding then
            Time.every 100 Tick

          else
            Sub.none
        ]
