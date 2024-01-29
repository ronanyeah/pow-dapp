module Update exposing (update)

import Dict
import Helpers.Http exposing (jsonResolver)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Maybe.Extra exposing (unwrap)
import Ports
import Task exposing (Task)
import Time
import Types exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UseKey key ->
            ( { model
                | view = ViewMint
                , grinding = False
                , nftId = Just key
              }
            , Ports.stopGrind ()
            )

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

        GenSelect key ->
            ( { model
                | match = key
              }
            , Cmd.none
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

                buildParams crit =
                    [ ( "criteria"
                      , crit
                            |> JE.object
                      )
                    , ( "count", JE.int 512 )
                    ]
                        |> JE.object

                newModel =
                    { model
                        | grinding = True
                        , vanity = []
                        , message = Nothing
                        , count = 0
                    }
            in
            case model.match of
                MatchStart ->
                    model.startInput
                        |> validate
                        |> unwrap
                            ( newModel
                            , [ ( "start", JE.string model.startInput )
                              ]
                                |> buildParams
                                |> Ports.vanity
                            )
                            (\err ->
                                ( { model | message = Just err }, Cmd.none )
                            )

                MatchEnd ->
                    model.endInput
                        |> validate
                        |> unwrap
                            ( newModel
                            , [ ( "end", JE.string model.endInput )
                              ]
                                |> buildParams
                                |> Ports.vanity
                            )
                            (\err ->
                                ( { model | message = Just err }, Cmd.none )
                            )

                MatchBoth ->
                    [ validate model.startInput
                    , validate model.endInput
                    ]
                        |> List.filterMap identity
                        |> List.head
                        |> unwrap
                            ( newModel
                            , [ ( "end", JE.string model.endInput )
                              , ( "start", JE.string model.startInput )
                              ]
                                |> buildParams
                                |> Ports.vanity
                            )
                            (\err ->
                                ( { model | message = Just err }, Cmd.none )
                            )

        Generate ->
            ( { model | grinding = True }, Ports.generatePow () )

        StopGrind ->
            ( { model | grinding = False }, Ports.stopGrind () )

        SelectWallet ->
            ( model, Ports.openWalletMenu () )

        SubmitId ->
            String.toInt model.idInput
                |> unwrap ( model, Cmd.none )
                    (\n ->
                        if String.contains "0" model.idInput || n < 1 then
                            ( model, Cmd.none )

                        else
                            ( { model
                                | idCheck = Nothing
                                , idInProg = n
                                , idWaiting = True
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

        SetView str ->
            ( { model
                | view = str
              }
            , Cmd.none
            )

        GrindCb data ->
            ( { model
                | count = model.count + data.count
                , keys = model.keys ++ data.keys
              }
            , data.keys
                |> List.filterMap .nft
                |> List.map
                    (\nft ->
                        accountExists model.rpc nft.register
                            |> Task.attempt
                                (Result.toMaybe >> AccountCheckCb nft.id)
                    )
                |> Cmd.batch
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

        ContainChange str ->
            ( { model
                | containInput = str
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

        AccountCheckCb pubkey res ->
            res
                |> unwrap
                    ( model, Cmd.none )
                    (\avail ->
                        ( { model
                            | availability =
                                model.availability
                                    |> Dict.insert pubkey avail
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
                | status = Nothing
                , nftId = Nothing
                , err = Nothing
                , mintSig = Nothing
              }
            , Cmd.none
            )

        FileCb val ->
            ( { model
                | status = Nothing
                , walletInUse = True
              }
            , Ports.fileOut val
            )

        VanityCb data ->
            let
                total =
                    model.count + data.count

                exit =
                    --total >= 1000000
                    False
            in
            ( { model
                | count = total
                , vanity = model.vanity ++ data.keys
                , grinding = not exit
              }
            , if exit then
                Ports.stopGrind ()

              else
                Cmd.none
            )

        NftCb val ->
            ( { model
                | nftId = Just val
                , walletInUse = False
              }
            , val.nft
                |> unwrap Cmd.none
                    (\nft ->
                        nft.register
                            |> accountExists model.rpc
                            |> Task.attempt
                                (Result.toMaybe >> AccountCheckCb nft.id)
                    )
            )

        WalletCb val ->
            ( { model | wallet = Just val }
            , Cmd.none
            )

        AvailCb val ->
            ( { model
                | status = Just val
                , walletInUse = False
              }
            , Cmd.none
            )

        Disconnect ->
            ( model
            , Cmd.none
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
