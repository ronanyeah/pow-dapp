module Update exposing (update)

import Dict exposing (Dict)
import Helpers.Http exposing (jsonResolver)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Maybe.Extra exposing (unwrap)
import Misc exposing (..)
import Ports
import Task exposing (Task)
import Time
import Types exposing (..)


buildParams crit =
    [ ( "criteria"
      , crit
            |> unwrap JE.null JE.object
      )
    , ( "count", JE.int 512 )
    ]
        |> JE.object


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick key ->
            ( { model
                | now = Time.posixToMillis key
              }
            , Cmd.none
            )

        StartTimeCb key ->
            ( { model
                | startTime = key
              }
            , Cmd.none
            )

        SetViewGen n ->
            ( { model
                | viewGen = Just n
                , grindMessage = Nothing
                , view = ViewGenerator
              }
            , Cmd.none
            )

        GenSelect key ->
            ( { model
                | match = key
              }
            , Cmd.none
            )

        PowGen ->
            ( { model
                | grinding = True
                , keys = []
                , grindMessage = Nothing
                , count = 0
              }
            , buildParams Nothing
                |> Ports.startGrind
            )

        VanityGen ->
            let
                valid =
                    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

                validate str =
                    [ if String.isEmpty str then
                        Just "Input is empty"

                      else
                        Nothing
                    , if
                        String.any
                            (\ch ->
                                String.contains (String.fromChar ch) valid
                                    |> not
                            )
                            str
                      then
                        Just "Invalid characters"

                      else
                        Nothing
                    ]
                        |> List.filterMap identity
                        |> List.head

                exec =
                    case model.match of
                        MatchStart ->
                            model.startInput
                                |> validate
                                |> unwrap
                                    ([ ( "start", JE.string model.startInput )
                                     ]
                                        |> Just
                                        |> buildParams
                                        |> Ports.startGrind
                                        |> Ok
                                    )
                                    Err

                        MatchEnd ->
                            model.endInput
                                |> validate
                                |> unwrap
                                    ([ ( "end", JE.string model.endInput )
                                     ]
                                        |> Just
                                        |> buildParams
                                        |> Ports.startGrind
                                        |> Ok
                                    )
                                    Err

                        MatchBoth ->
                            [ validate model.startInput
                            , validate model.endInput
                            ]
                                |> List.filterMap identity
                                |> List.head
                                |> unwrap
                                    ([ ( "end", JE.string model.endInput )
                                     , ( "start", JE.string model.startInput )
                                     ]
                                        |> Just
                                        |> buildParams
                                        |> Ports.startGrind
                                        |> Ok
                                    )
                                    Err
            in
            case exec of
                Ok cmd ->
                    ( { model
                        | grinding = True
                        , keys = []
                        , grindMessage = Nothing
                        , count = 0
                      }
                    , cmd
                    )

                Err err ->
                    ( { model | grindMessage = Just err }, Cmd.none )

        StopGrind ->
            ( { model | grinding = False }, Ports.stopGrind () )

        SelectWallet ->
            ( model, Ports.openWalletMenu () )

        SubmitId ->
            if String.contains "0" model.idInput then
                ( { model
                    | searchMessage = Just "'0' is not a valid Solana address character."
                  }
                , Cmd.none
                )

            else
                String.toInt model.idInput
                    |> unwrap ( model, Cmd.none )
                        (\n ->
                            if n < 1 then
                                ( model, Cmd.none )

                            else if n > u32_MAX then
                                ( { model
                                    | searchMessage =
                                        "The maximum possible ID is "
                                            ++ String.fromInt u32_MAX
                                            ++ "."
                                            |> Just
                                  }
                                , Cmd.none
                                )

                            else
                                ( { model
                                    | idCheck = Nothing
                                    , idInProg = n
                                    , idWaiting = True
                                    , searchMessage = Nothing
                                  }
                                , Ports.checkId n
                                )
                        )

        MintNft bts ->
            ( { model
                | walletInUse = True
              }
            , Ports.mintNft bts
            )

        CountCb n ->
            ( { model
                | count = model.count + n
              }
            , Cmd.none
            )

        SetView str ->
            ( { model
                | view = str
              }
            , Cmd.none
            )

        GrindCb key ->
            ( { model
                | keys = model.keys ++ [ key ]
              }
              --, checkRegisterIfNecessary model.nftExists model.rpc key
            , Cmd.none
            )

        MintCb sig ->
            ( { model
                | mintSig = Just sig
                , walletInUse = False
              }
            , Cmd.none
            )

        MintErr ->
            ( { model
                | walletInUse = False
              }
            , Cmd.none
            )

        IdInputChange str ->
            ( { model
                | idInput = str
                , idCheck = Nothing
              }
            , Cmd.none
            )

        StartChange str ->
            ( { model
                | startInput = str
              }
            , Cmd.none
            )

        EndChange str ->
            ( { model
                | endInput = str
              }
            , Cmd.none
            )

        IdCheckCb exists ->
            ( { model
                | idCheck = Just exists
                , idWaiting = False
              }
            , Cmd.none
            )

        AccountCheckCb id res ->
            res
                |> unwrap
                    ( model, Cmd.none )
                    (\exists ->
                        ( { model
                            | nftExists =
                                model.nftExists
                                    |> Dict.insert id exists
                          }
                        , Cmd.none
                        )
                    )

        AddrCb addr ->
            ( { model
                | demoAddress = addr
              }
            , Cmd.none
            )

        Reset ->
            ( { model
                | keypairMessage = Nothing
                , loadedKeypair = Nothing
                , err = Nothing
                , mintSig = Nothing
              }
            , Cmd.none
            )

        FileCb val ->
            ( { model
                | keypairMessage = Nothing
                , walletInUse = True
              }
            , Ports.fileOut val
            )

        SelectNft val ->
            ( { model
                | loadedKeypair = Just val
                , view = ViewMint
                , grinding = False
                , mintSig = Nothing
              }
            , [ Ports.stopGrind ()
              , val.nft
                    |> unwrap Cmd.none
                        (\nft ->
                            nft.register
                                |> accountExists model.rpc
                                |> Task.attempt
                                    (Result.toMaybe >> AccountCheckCb nft.id)
                        )
              ]
                |> Cmd.batch
            )

        WalletCb val ->
            ( { model | wallet = Just val }
            , Cmd.none
            )

        LoadKeypairCb res ->
            res
                |> unwrap
                    ( { model
                        | keypairMessage = Just "Keypair file failed to parse."
                        , walletInUse = False
                      }
                    , Cmd.none
                    )
                    (\key ->
                        ( { model
                            | loadedKeypair = Just key
                            , walletInUse = False
                            , nftExists =
                                key.nft
                                    |> unwrap
                                        model.nftExists
                                        (\nft ->
                                            model.nftExists
                                                |> Dict.insert nft.id
                                                    (nft.mint /= Nothing)
                                        )
                          }
                        , Cmd.none
                        )
                    )

        Disconnect ->
            ( model
            , Cmd.none
            )


checkRegisterIfNecessary : Dict Int Bool -> String -> Key -> Cmd Msg
checkRegisterIfNecessary nftExists rpc key =
    let
        maybeCheck =
            key.nft
                |> Maybe.andThen
                    (\nft ->
                        Dict.get nft.id nftExists
                            |> unwrap (Just nft)
                                (\exists ->
                                    if exists then
                                        Nothing

                                    else
                                        Just nft
                                )
                    )
    in
    maybeCheck
        |> unwrap Cmd.none
            (\nft ->
                nft.register
                    |> accountExists rpc
                    |> Task.attempt
                        (Result.toMaybe >> AccountCheckCb nft.id)
            )


accountExists : String -> String -> Task Http.Error Bool
accountExists rpc pubkey =
    Http.task
        { method = "POST"
        , headers = []
        , url = rpc
        , body =
            [ ( "jsonrpc", JE.string "2.0" )
            , ( "id", JE.int 1 )
            , ( "method", JE.string "getAccountInfo" )
            , ( "params"
              , [ pubkey
                    |> JE.string
                , [ ( "encoding", JE.string "base58" )
                  ]
                    |> JE.object
                ]
                    |> JE.list identity
              )
            ]
                |> JE.object
                |> Http.jsonBody
        , resolver =
            jsonResolver
                (JD.nullable JD.value
                    |> JD.at [ "result", "value" ]
                    |> JD.map Maybe.Extra.isJust
                )
        , timeout = Nothing
        }
