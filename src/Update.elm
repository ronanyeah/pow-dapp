module Update exposing (update)

import Array exposing (Array)
import Base64
import BigInt exposing (BigInt)
import Dict
import Helpers.Http exposing (jsonResolver, parseError)
import Hex
import Http
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Json.Encode as JE
import List.Extra
import Maybe.Extra exposing (unwrap)
import Misc exposing (..)
import Ports
import Result.Extra exposing (unpack)
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

        RefreshPool poolId ->
            model.wallet
                |> Maybe.andThen .token
                |> unwrap ( model, Cmd.none )
                    (\token ->
                        ( { model
                            | wsStatus = model.wsStatus
                          }
                        , Http.task
                            { method = "GET"
                            , headers =
                                [ Http.header "X-POW-AUTH" token
                                ]
                            , url = "/api/fresh/" ++ poolId
                            , body = Http.emptyBody
                            , resolver = jsonResolver decodeHit
                            , timeout = Nothing
                            }
                            |> Task.attempt RefreshCb
                        )
                    )

        RefreshCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | walletInUse = model.walletInUse
                          }
                        , Ports.log (parseError err)
                        )
                    )
                    (\hit ->
                        ( { model
                            | hits =
                                model.hits
                                    |> Dict.insert hit.mint hit
                          }
                        , Cmd.none
                        )
                    )

        WsConnect ->
            model.wallet
                |> Maybe.andThen .token
                |> unwrap ( model, Cmd.none )
                    (\token ->
                        ( { model
                            | wsStatus = Connecting
                          }
                        , Ports.wsConnect token
                        )
                    )

        SignMessage ->
            ( { model | walletInUse = True }
            , Ports.signIn ()
            )

        WsDisconnected ->
            ( { model | wsStatus = Standby }
            , Cmd.none
            )

        WsConnectCb val ->
            ( { model
                | wsStatus =
                    if val then
                        Live

                    else
                        Standby
              }
            , Cmd.none
            )

        HitCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | walletInUse = False
                          }
                        , Ports.log (JD.errorToString err)
                        )
                    )
                    (\hit ->
                        ( { model
                            | hits =
                                model.hits
                                    |> Dict.insert hit.mint hit
                                    |> Dict.toList
                                    |> List.sortBy (\( _, v ) -> v.openTime)
                                    |> List.reverse
                                    |> List.take 30
                                    |> Dict.fromList
                          }
                        , Cmd.none
                        )
                    )

        ClearResults ->
            ( { model
                | hits = Dict.empty
              }
            , Cmd.none
            )

        ToggleUtility ->
            ( { model
                | viewUtility =
                    if model.viewUtility == ViewUtility then
                        ViewInventory

                    else
                        ViewUtility
              }
            , Ports.wsDisconnect ()
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
            let
                newModel =
                    model
                        |> (\m ->
                                { m
                                    | idCheck =
                                        { inProg = False
                                        , mint = Nothing
                                        , id = Nothing
                                        }
                                }
                           )
            in
            if String.contains "0" model.idInput then
                ( { newModel
                    | searchMessage = Just "'0' is not a valid Solana address character."
                  }
                , Cmd.none
                )

            else
                String.toInt model.idInput
                    |> unwrap
                        ( model, Cmd.none )
                        (\n ->
                            if n < 1 then
                                ( model, Cmd.none )

                            else if n > u32_MAX then
                                ( { newModel
                                    | searchMessage =
                                        "The maximum possible ID is "
                                            ++ String.fromInt u32_MAX
                                            ++ "."
                                            |> Just
                                  }
                                , Cmd.none
                                )

                            else
                                ( { newModel
                                    | searchMessage = Nothing
                                  }
                                , Ports.findRegister n
                                )
                        )

        FindRegisterCb data ->
            ( { model
                | idCheck =
                    { inProg = True
                    , id = Just data.id
                    , mint = Nothing
                    }
              }
            , getMint model.rpc data.register
                |> Task.attempt IdMintCheckCb
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

        SetView v ->
            ( { model
                | view = v
              }
            , Ports.wsDisconnect ()
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

        WalletErr ->
            ( { model
                | walletInUse = False
              }
            , Cmd.none
            )

        IdInputChange str ->
            ( { model
                | idInput = str
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

        SelectNft key ->
            ( { model
                | loadedKeypair = Just key
                , view = ViewMint
                , grinding = False
                , mintSig = Nothing
                , keypairCheck =
                    { inProg = True, mint = Nothing }
              }
            , [ Ports.stopGrind ()
              , key.nft
                    |> unwrap Cmd.none
                        (.register
                            >> getMint model.rpc
                            >> Task.attempt KeypairMintCheckCb
                        )
              ]
                |> Cmd.batch
            )

        InventoryCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | walletInUse = False
                          }
                        , Ports.log (parseError err)
                        )
                    )
                    (\supply ->
                        ( { model
                            | inventory = Just supply
                            , walletInUse = False
                          }
                        , Cmd.none
                        )
                    )

        FetchInventory ->
            model.wallet
                |> Maybe.andThen .token
                |> unwrap ( model, Cmd.none )
                    (\token ->
                        ( { model
                            | walletInUse = True
                            , inventory = Nothing
                          }
                        , getInventory token
                            |> Task.attempt InventoryCb
                        )
                    )

        LoginCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | walletInUse = False
                          }
                        , Ports.log (parseError err)
                        )
                    )
                    (\token ->
                        ( { model
                            | wallet =
                                model.wallet
                                    |> Maybe.map
                                        (\wl ->
                                            { wl
                                                | token = Just token
                                            }
                                        )
                          }
                        , getInventory token
                            |> Task.attempt InventoryCb
                        )
                    )

        SignInCb ( message, sig ) ->
            model.wallet
                |> unwrap
                    ( { model | walletInUse = False }
                    , Cmd.none
                    )
                    (\wl ->
                        ( { model | walletInUse = model.walletInUse }
                        , login wl.address message sig
                            |> Task.attempt LoginCb
                        )
                    )

        WalletCb val ->
            ( { model
                | wallet =
                    Just
                        { address = val
                        , token = Nothing
                        }
              }
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
                            , keypairCheck =
                                { inProg = True, mint = Nothing }
                          }
                        , key.nft
                            |> unwrap Cmd.none
                                (.register
                                    >> getMint model.rpc
                                    >> Task.attempt KeypairMintCheckCb
                                )
                        )
                    )

        IdMintCheckCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | idCheck =
                                model.idCheck
                                    |> (\kp ->
                                            { kp | inProg = False }
                                       )
                          }
                        , Ports.log (parseError err)
                        )
                    )
                    (\mMint ->
                        ( { model
                            | idCheck =
                                model.idCheck
                                    |> (\kp ->
                                            { kp
                                                | inProg = False
                                                , mint = Just mMint
                                            }
                                       )
                          }
                        , Cmd.none
                        )
                    )

        KeypairMintCheckCb res ->
            res
                |> unpack
                    (\err ->
                        ( { model
                            | keypairCheck =
                                model.keypairCheck
                                    |> (\kp ->
                                            { kp | inProg = False }
                                       )
                          }
                        , Ports.log (parseError err)
                        )
                    )
                    (\mMint ->
                        ( { model
                            | keypairCheck =
                                { inProg = False, mint = Just mMint }
                          }
                        , Cmd.none
                        )
                    )

        WsDisconnect ->
            ( model
            , Ports.wsDisconnect ()
            )

        Disconnect ->
            ( { model
                | wallet = Nothing
                , inventory = Nothing
                , hits = Dict.empty
              }
            , Ports.disconnectOut ()
            )

        Copy str ->
            ( model
            , Ports.copy str
            )


login : String -> String -> String -> Task Http.Error String
login address message hash =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/api/login"
        , body =
            [ ( "address", JE.string address )
            , ( "signature", JE.string hash )
            , ( "message", JE.string message )
            ]
                |> JE.object
                |> Http.jsonBody
        , resolver = jsonResolver JD.string
        , timeout = Nothing
        }


getInventory : String -> Task Http.Error Inventory
getInventory token =
    Http.task
        { method = "GET"
        , headers =
            [ Http.header "X-POW-AUTH" token
            ]
        , url = "/api/inventory"
        , body = Http.emptyBody
        , resolver =
            JD.succeed Inventory
                |> JDP.required "t1" JD.int
                |> JDP.required "t2" JD.int
                |> JDP.required "t3" JD.int
                |> JDP.required "t4" JD.int
                |> JDP.required "t5" JD.int
                |> JDP.required "t6" JD.int
                |> JDP.required "t7" JD.int
                |> JDP.required "t8" JD.int
                |> JDP.required "t9" JD.int
                |> JDP.required "t10" JD.int
                |> JDP.required "z" JD.int
                |> JDP.required "total" JD.int
                |> JDP.custom (JD.succeed False)
                |> JD.map
                    (\inv ->
                        { inv | utilityAccess = inv.total > 0 }
                    )
                |> jsonResolver
        , timeout = Nothing
        }


getMint : String -> String -> Task Http.Error (Maybe String)
getMint rpc pubkey =
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
                , [ ( "encoding", JE.string "base64" )
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
                (decodeAccountData
                    |> JD.map
                        (Maybe.andThen
                            (Base64.decode
                                >> Result.toMaybe
                                >> Maybe.andThen
                                    (List.drop (8 + 4 + 1)
                                        >> List.take 32
                                        >> bytesToBase58
                                    )
                            )
                        )
                )
        , timeout = Nothing
        }


decodeAccountData : JD.Decoder (Maybe String)
decodeAccountData =
    JD.field "result"
        (JD.field "value"
            (JD.nullable (JD.field "data" (JD.list JD.string)))
        )
        |> JD.map (Maybe.andThen List.head)


bigIntToInt =
    BigInt.toString
        >> String.toInt
        >> Maybe.withDefault 0


base58Alphabet : Array Char
base58Alphabet =
    String.toList "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        |> Array.fromList


bytesToBase58 : List Int -> Maybe String
bytesToBase58 bts =
    let
        encodeHelper : BigInt -> List Char -> List Char
        encodeHelper currentBigInt acc =
            if currentBigInt == BigInt.fromInt 0 then
                acc

            else
                BigInt.divmod currentBigInt (BigInt.fromInt 58)
                    |> Maybe.andThen
                        (\( quotient, remainder ) ->
                            Array.get
                                (bigIntToInt remainder)
                                base58Alphabet
                                |> Maybe.map
                                    (\char ->
                                        encodeHelper quotient (char :: acc)
                                    )
                        )
                    |> Maybe.withDefault acc
    in
    if List.length bts /= 32 then
        Nothing

    else
        byteArrayToBigInt bts
            |> Maybe.map
                (\value ->
                    let
                        enc =
                            encodeHelper value []

                        leadingOnes =
                            bts
                                |> List.Extra.takeWhile (\byte -> byte == 0)
                                |> List.length
                                |> (\n -> String.repeat n "1")
                    in
                    leadingOnes ++ String.fromList enc
                )


byteArrayToBigInt : List Int -> Maybe BigInt
byteArrayToBigInt =
    List.map Hex.toString
        >> List.map (String.padLeft 2 '0')
        >> String.concat
        >> (++) "0x"
        >> BigInt.fromHexString
