module View exposing (view)

import BigInt
import Colors exposing (..)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Float.Extra
import FormatNumber
import FormatNumber.Locales exposing (usLocale)
import Helpers.View exposing (cappedHeight, cappedWidth, onKeydown, style, when, whenAttr, whenJust)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Img
import Json.Decode as JD
import Json.Encode as JE
import List.Extra
import Maybe.Extra exposing (unwrap)
import Misc exposing (..)
import Types exposing (..)
import Url


view : Model -> Html Msg
view model =
    (if model.screen.width >= 1150 then
        --viewPalette
        viewWide model

     else
        viewThin model
    )
        |> Element.layoutWith
            { options =
                [ Element.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ width fill
            , height fill
            , Font.size 19
            , mainFont
            , Background.gradient
                { angle = degrees 30
                , steps =
                    [ lightBlue
                    , lightPurple
                    , lightPurple
                    , lightBlue
                    , lightPurple
                    , lightPurple
                    , lightBlue
                    , lightPurple
                    , lightPurple
                    , lightBlue
                    ]
                        |> List.reverse
                }
            ]


viewWide : Model -> Element Msg
viewWide model =
    let
        logo =
            powLogo (fork model.isShort 170 250)
    in
    [ [ [ logo
        , [ [ [ text "The world's first "
              , text "proof-of-work"
                    |> el [ comicFont ]
              , text " NFT"
              ]
                |> paragraph [ Font.center ]
            , text bang
                |> el [ centerX ]
            ]
                |> column
                    [ Background.color white
                    , spacing 15
                    , padding 10
                    , shadow
                    , Font.size (fork model.isMobile 19 24)
                    , width fill
                    ]
          , [ viewX
            , image [ height <| px 26 ]
                { src = "/github.png"
                , description = ""
                }
                |> linkOut "https://github.com/ronanyeah/pow-dapp" [ padding 3 ]
            ]
                |> row [ spacing 10, centerX ]
          ]
            |> column
                [ cappedWidth (fork model.isMobile 160 250)
                , spacing 20
                ]
        ]
            |> row [ spacing 10, centerX ]
      , viewMintStatus model
            |> el [ alignBottom, width fill ]
      , viewBanner model
            |> el
                [ width fill
                , alignBottom
                ]
      ]
        |> column
            [ height fill
            , spacing 20
            , cappedWidth 500
            , fadeIn
            ]
    , [ viewNav model
      , (case model.view of
            ViewHome ->
                viewInfo model

            ViewGenerator ->
                viewGeneratorIntro model

            ViewMint ->
                viewMint model

            ViewAvails ->
                viewAvails model

            ViewHolder ->
                viewHolder model
        )
            |> el
                [ Background.color white
                , paddingXY (fork model.isMobile 15 30) 20
                , shadow
                , height fill
                , width fill
                ]
      ]
        |> column
            [ height fill
            , fadeIn
            , width fill
            ]
    ]
        |> row
            [ width <| px 1250
            , centerX
            , height fill
            , cappedHeight 820
            , padding 30
            , spacing 30
            ]


viewHolder model =
    case model.viewUtility of
        ViewInventory ->
            viewInventory model

        ViewUtility ->
            model.wallet
                |> unwrap (text "no wallet")
                    (.holder >> viewMemescan model)


viewInventory : Model -> Element Msg
viewInventory model =
    [ [ [ text ("Holder Access Area  " ++ bang)
            |> el [ Font.bold, Font.size 22 ]
        ]
            |> row [ width fill, spaceEvenly ]
      ]
        |> row [ width fill, spaceEvenly ]
    , model.wallet
        |> unwrap
            ([ para
                [ Font.center
                , width <| px 300
                ]
                "Connect a wallet to view inventory and access utility features."
             , selectWallet
                |> el
                    [ centerX
                    ]
             ]
                |> column [ centerX, spacing 40, paddingXY 0 40 ]
            )
            (\wallet ->
                [ [ [ text "Wallet Connected"
                        |> el [ Font.bold ]
                    , text "Disconnect"
                        |> btn (Just Disconnect)
                            [ Font.underline
                            , Font.size 12
                            , alignRight
                            ]
                    ]
                        |> row [ spacing 30 ]
                  , text
                        (String.left 11 wallet.address
                            ++ "..."
                            ++ String.right 11 wallet.address
                        )
                        |> el [ Font.size 17 ]
                  ]
                    |> column
                        [ spacing 10
                        , padding 10
                        , Border.rounded 10
                        , Border.width 1
                        , centerX
                        ]
                , if wallet.token == Nothing then
                    [ [ text "🔐  Sign in to proceed"
                            |> baseBtn
                                (if model.walletInUse then
                                    Nothing

                                 else
                                    Just SignMessage
                                )
                                []
                      , spinner 20
                            |> el [ centerX ]
                            |> when model.walletInUse
                      ]
                        |> column [ spacing 10, centerX ]
                    ]
                        |> column [ spacing 20, centerX ]

                  else
                    [ model.inventory
                        |> unwrap
                            (if model.walletInUse then
                                [ text "Inventory loading"
                                , spinner 30
                                    |> el [ centerX ]
                                ]
                                    |> column [ spacing 20, centerX ]

                             else
                                text "Load inventory"
                                    |> baseBtn (Just FetchInventory)
                                        [ centerX
                                        ]
                            )
                            (\inventory ->
                                let
                                    badge t n =
                                        [ text ("Tier " ++ t ++ ":")
                                            |> el [ Font.bold ]
                                        , text (String.fromInt n)
                                            |> el [ alignRight ]
                                        ]
                                            |> row [ spacing 7, width fill ]
                                in
                                [ [ [ text "Inventory"
                                        |> el
                                            [ Background.color black
                                            , padding 10
                                            , Font.color white
                                            ]
                                    , [ text (bang ++ " POW total:")
                                            |> el [ Font.bold, Font.size 22 ]
                                      , text (String.fromInt inventory.total)
                                            |> el [ Font.size 22 ]
                                      ]
                                        |> row [ spacing 10, paddingXY 20 0 ]
                                    ]
                                        |> row [ width fill, spaceEvenly ]
                                  , [ [ [ badge "1" inventory.t1
                                        , badge "2" inventory.t2
                                        , badge "3" inventory.t3
                                        , badge "4" inventory.t4
                                        ]
                                            |> column [ spacing 10 ]
                                      , [ badge "5" inventory.t5
                                        , badge "6" inventory.t6
                                        , badge "7" inventory.t7
                                        , badge "8" inventory.t8
                                        ]
                                            |> column [ spacing 10 ]
                                      , [ badge "9" inventory.t9
                                        , badge "10" inventory.t10
                                        , badge "Z" inventory.z
                                            |> el [ alignBottom, width fill ]
                                        ]
                                            |> column [ spacing 10, height fill ]
                                      ]
                                        |> row
                                            [ spacing 20
                                            , Font.size 15
                                            , Border.width 1
                                            , padding 10
                                            , centerX
                                            ]
                                    , text "Refresh"
                                        |> btn (Just FetchInventory)
                                            [ Font.size 15
                                            , Font.underline
                                            , centerX
                                            ]
                                    ]
                                        |> column [ padding 10, spacing 10, width fill ]
                                  ]
                                    |> column
                                        [ Border.width 1
                                        , width fill
                                        , spacing 10
                                        ]
                                ]
                                    |> column [ centerX, spacing 30, width fill ]
                            )
                    , [ [ text "Tools"
                            |> el
                                [ Background.color black
                                , padding 10
                                , Font.color white
                                ]
                        , [ text "Access:"
                                |> el [ Font.size 17 ]
                          , text
                                (if wallet.holder then
                                    "✅"

                                 else
                                    "❌"
                                )
                          ]
                            |> row [ spacing 10, paddingXY 20 0 ]
                        ]
                            |> row [ width fill, spaceEvenly ]
                      , text (emTarget ++ "  Memecoin Liquidity Tracker")
                            |> btn (Just ToggleUtility)
                                [ Font.size 17
                                , Font.underline
                                , centerX
                                ]
                            |> el [ padding 20 ]
                      ]
                        |> column [ Border.width 1, width fill ]
                    ]
                        |> column [ spacing 30, width fill ]
                ]
                    |> column [ spacing 30, width fill ]
            )
    ]
        |> column [ spacing 20, width fill, height fill ]


secondsDiff : Int -> Int -> Int
secondsDiff now age =
    (now // 1000) - age


formatTime : Int -> Int -> String
formatTime now age =
    let
        secs =
            secondsDiff now age
    in
    if secs > 7200 then
        String.fromInt (round (toFloat secs / 3600)) ++ " hours"

    else if secs > 120 then
        String.fromInt (round (toFloat secs / 60)) ++ " minutes"

    else
        String.fromInt secs ++ " seconds"


viewBubble k v =
    newTabLink [ hover ]
        { url =
            "https://solscan.io/account/"
                ++ v
        , label =
            [ text k
                |> el [ Font.bold ]
            , text (String.left 9 v ++ "...")
            ]
                |> row
                    [ spacing 10
                    , Font.size 13
                    , padding 5
                    , Border.rounded 5
                    , Border.width 1
                    ]
        }


viewTag k v =
    [ text (k ++ ":")
        |> el [ Font.bold ]
    , text v
    ]
        |> row [ spacing 10 ]


viewMintStatus : Model -> Element Msg
viewMintStatus model =
    [ text ("Mint Status " ++ bang)
        |> el [ titleFont, Font.size 17 ]
    , viewMintRow 1
        9
        (Just 9)
        MintedOut
        [ "pow"
        , "4"
        , "GJAuA9HB1tZnyAxTyw7VKz2wovgcq9sezJoKqM4"
        ]
    , viewMintRow 2
        81
        (Just 81)
        MintedOut
        [ "pow"
        , "39"
        , "Q4JyQCnNPkAdBUqDvhGmehDeAueycrpmZJ5Aur"
        ]
    , viewMintRow 3
        729
        (Just 729)
        MintedOut
        [ "pow"
        , "985"
        , "Q4pDoFu2717KWq9otDP6chkiTdXbb2B7eKAwo"
        ]
    , viewMintRow 4
        6558
        (Just 6561)
        InProgress
        [ "pow"
        , "4269"
        , "mWh13DW3DvgBTuZyA33gr1KX2GcsQMhXumgX"
        ]
    , viewMintRow 5
        5561
        Nothing
        Closed
        [ "pow"
        , "56136"
        , "HjhNPQZfTujY9c4Ecr8GPFGM1vXm1T6GMc5"
        ]
    , viewMintRow 6
        930
        Nothing
        Closed
        [ "pow"
        , "745335"
        , "Mx3r2vfoZPUVSk2hUNSXAt57QWFup2o4wx"
        ]
    , viewMintRow 7
        176
        Nothing
        Closed
        [ "pow"
        , "9385746"
        , "KAZpMXnUq8WFjaHSPBsemLVcSXbcBfa6p"
        ]
    , viewMintRow 8
        31
        Nothing
        Closed
        [ "pow"
        , "14227828"
        , "u7Hoyk6GL3CqwzJpTPxNQPbraXunpkMd"
        ]
    , viewMintRow 9
        17
        Nothing
        InProgress
        [ "pow"
        , "537113567"
        , "RAdU8GRzPjsZDB3sHn2RqFa82yki4ph"
        ]
    , viewMintRow 10
        2
        Nothing
        InProgress
        [ "pow"
        , "2148269433"
        , "MsT7eLDqXqeji8DQNKSrA45uhkioEM"
        ]
    , para [ Font.italic, Font.size 14 ] "Note: '0' is not a valid character in Solana addresses, so cannot be in a POW ID."
    ]
        |> column
            [ spacing 10
            , padding 10
            , Background.color white
            , width fill
            , Font.size (fork model.isShort 12 15)
            , Border.width 1
            ]


viewMintRow tier count max status addr =
    [ [ text ("Tier " ++ String.fromInt tier ++ ":")
            |> el [ Font.bold ]
      , text
            (String.fromInt count
                ++ (max
                        |> unwrap ""
                            (\n -> "/" ++ String.fromInt n)
                   )
            )
      , (case status of
            MintedOut ->
                "✅"

            InProgress ->
                "🔍"

            Closed ->
                "🔒"
        )
            |> text
      ]
        |> row [ spacing 10 ]
    , newTabLink [ hover ]
        { url =
            "https://solscan.io/token/"
                ++ String.concat addr
        , label = renderPowTrunc addr True
        }
    ]
        |> row [ spacing 10, width fill, spaceEvenly ]


viewThin : Model -> Element Msg
viewThin model =
    let
        header =
            if model.view == ViewHome then
                [ [ powLogo 120
                        |> el [ centerX ]
                  , viewX
                  ]
                    |> column [ spacing 10, centerX ]
                , [ [ [ text "The world's first "
                      , text "proof-of-work"
                            |> el [ comicFont ]
                      , text " NFT"
                      ]
                        |> paragraph [ Font.center ]
                    , text bang
                        |> el [ centerX ]
                    ]
                        |> column
                            [ Background.color white
                            , spacing 15
                            , padding 10
                            , shadow
                            , Font.size (fork model.isMobile 19 24)
                            , width fill
                            ]
                  ]
                    |> column
                        [ cappedWidth (fork model.isMobile 160 250)
                        , spacing 20
                        ]
                ]
                    |> row [ width fill, spaceEvenly ]

            else
                [ powLogo 30
                    |> btn (Just (SetView ViewHome)) []
                , text "☰"
                    |> el
                        [ Font.size 20
                        , padding 10
                        , Background.color green
                        , if model.menuDropdown then
                            Border.roundEach
                                { bottomLeft = 0
                                , bottomRight = 0
                                , topLeft = 10
                                , topRight = 10
                                }

                          else
                            Border.rounded 10
                        ]
                    |> btn (Just ToggleDropdown) []
                ]
                    |> row
                        [ width fill
                        , spaceEvenly
                        , navContent
                            |> List.drop 1
                            |> List.map
                                (\( txt, v ) ->
                                    text txt
                                        |> btn (Just (SetView v)) []
                                )
                            |> column
                                [ spacing 20
                                , Background.color green
                                , alignRight
                                , padding 20
                                , Border.roundEach
                                    { bottomLeft = 10
                                    , bottomRight = 10
                                    , topLeft = 10
                                    , topRight = 0
                                    }
                                ]
                            |> below
                            |> whenAttr model.menuDropdown
                        ]
    in
    [ header
    , [ viewNavMobile model
            |> when (model.view == ViewHome)
      , (case model.view of
            ViewHome ->
                viewInfo model

            ViewGenerator ->
                viewGeneratorIntro model

            ViewMint ->
                viewMint model

            ViewAvails ->
                viewAvails model

            ViewHolder ->
                viewHolder model
        )
            |> el
                [ Background.color white
                , paddingXY (fork model.isMobile 15 30) 20
                , shadow
                , height fill
                , width fill
                , scrollbarY
                ]
      ]
        |> column [ spacing 10, width fill, height fill ]
    , viewBanner model
        |> el
            [ fork model.isMobile (width fill) centerX
            , alignBottom
            ]
        |> when (model.view == ViewHome)
    ]
        |> column
            [ padding 15
            , spacing 10
            , height fill
            , fork model.isMobile (width fill) centerX
            , fadeIn
            , scrollbarY
                |> whenAttr model.isMobile
            ]


viewGeneratorIntro model =
    model.viewGen
        |> unwrap
            ([ para
                [ Font.center
                , Font.size 25
                ]
                "Welcome to the POW keypair generator!"
             , para [ Font.center, Font.italic ] "What do you want to do?"
             , text (bang ++ "  Generate a POW NFT")
                |> baseBtn (Just (SetViewGen True)) [ centerX ]
             , text "🪄  Generate a Solana vanity wallet"
                |> baseBtn (Just (SetViewGen False)) [ centerX ]
             ]
                |> column [ spacing 30, width fill, paddingXY 0 40 ]
            )
            (viewGenerator model)


viewGenerator model viewGen =
    let
        start =
            Input.text
                [ width <| px 100
                , Html.Attributes.maxlength 10
                    |> htmlAttribute
                ]
                { label =
                    text "Starts With"
                        |> Input.labelAbove [ Font.size 15 ]
                , onChange = StartChange
                , placeholder = Nothing
                , text = model.startInput
                }

        end =
            Input.text
                [ width <| px 100
                , Html.Attributes.maxlength 10
                    |> htmlAttribute
                ]
                { label =
                    text "Ends With"
                        |> Input.labelAbove [ Font.size 15 ]
                , onChange = EndChange
                , placeholder = Nothing
                , text = model.endInput
                }
    in
    [ [ para [ titleFont, Font.size (fork model.isMobile 17 20) ] "Keypair Generator"
      , text "Learn more"
            |> linkOut "https://www.quicknode.com/guides/solana-development/getting-started/how-to-create-a-custom-vanity-wallet-address-using-solana-cli"
                [ Font.underline
                , Font.size 16
                , alignBottom
                , Font.italic
                ]
      ]
        |> row [ width fill ]
    , [ text "MODE"
            |> el [ Font.bold ]
      , [ text ("POW " ++ bang)
            |> btn (Just (SetViewGen True))
                [ Border.width 1
                    |> whenAttr viewGen
                , padding 10
                ]
        , text "VANITY"
            |> btn (Just (SetViewGen False))
                [ Border.width 1
                    |> whenAttr (not viewGen)
                , padding 10
                ]
        ]
            |> row [ spacing 10 ]
      ]
        |> row [ spacing 10 ]
    , if viewGen then
        if model.grinding then
            [ [ text "Generation in progress"
                    |> when (not model.isMobile)
              , spinner 15
              ]
                |> row [ spacing 10, Font.size 13 ]
            , text "STOP"
                |> btn (Just StopGrind)
                    [ titleFont
                    , Border.width 1
                    , paddingXY 15 10
                    , Background.color red
                    , Border.rounded 5
                    , alignRight
                    , Font.size (fork model.isMobile 17 19)
                    ]
            ]
                |> column [ spacing 10, alignRight ]

        else
            text "START"
                |> btn (Just PowGen)
                    [ titleFont
                    , Border.width 1
                    , paddingXY 15 10
                    , Background.color green
                    , Border.rounded 5
                    , Font.size (fork model.isMobile 17 19)
                    , alignRight
                    ]

      else
        [ Input.radioRow
            [ paddingXY 10 10
            , width fill
            , spacing 20
            , Font.size 17
            , Background.color lightBlue
            , Border.roundEach
                { bottomLeft = 0, bottomRight = 5, topLeft = 5, topRight = 5 }
            ]
            { onChange = GenSelect
            , selected = Just model.match
            , label = Input.labelHidden ""
            , options =
                let
                    prefix =
                        if model.isMobile then
                            ""

                        else
                            "Match "
                in
                [ text (prefix ++ "Start")
                    |> el [ hover ]
                    |> Input.option MatchStart
                , text (prefix ++ "End")
                    |> el [ hover ]
                    |> Input.option MatchEnd
                , text (prefix ++ "Both")
                    |> el [ hover ]
                    |> Input.option MatchBoth
                ]
            }
        , [ (case model.match of
                MatchStart ->
                    start

                MatchEnd ->
                    end

                MatchBoth ->
                    [ start
                    , end
                    ]
                        |> row [ spacing 15 ]
            )
                |> el
                    [ Background.color lightBlue
                    , padding 10
                    , Border.roundEach
                        { bottomLeft = 5, bottomRight = 5, topLeft = 0, topRight = 0 }
                    ]
          , if model.grinding then
                [ [ text "Generation in progress"
                        |> when (not model.isMobile)
                  , spinner 15
                  ]
                    |> row [ spacing 10, Font.size 13 ]
                , text "STOP"
                    |> btn (Just StopGrind)
                        [ titleFont
                        , Border.width 1
                        , paddingXY 15 10
                        , Background.color red
                        , Border.rounded 5
                        , alignRight
                        , Font.size (fork model.isMobile 17 19)
                        ]
                ]
                    |> column [ spacing 10, alignRight ]

            else
                text "START"
                    |> btn (Just VanityGen)
                        [ titleFont
                        , Border.width 1
                        , paddingXY 15 10
                        , Background.color green
                        , Border.rounded 5
                        , Font.size (fork model.isMobile 17 19)
                        , alignRight
                        ]
          ]
            |> row [ width fill ]
        ]
            |> column [ width fill ]
    , model.grindMessage
        |> whenJust
            (\txt ->
                text
                    ("⚠️  " ++ txt)
            )
    , model.keys
        |> List.map
            (\key ->
                let
                    tierLabel =
                        key.nft
                            |> whenJust
                                (\nft ->
                                    if List.member nft.tier haltedTiers then
                                        text
                                            ("Tier "
                                                ++ String.fromInt nft.tier
                                                ++ " Mint is closed"
                                            )

                                    else if List.member nft.tier completedTiers then
                                        text
                                            ("All Tier "
                                                ++ String.fromInt nft.tier
                                                ++ " NFTs have been claimed"
                                            )

                                    else
                                        text "Check 🔍"
                                            |> btn (Just (SelectNft key))
                                                [ padding 5
                                                , Background.color white
                                                , Border.rounded 5
                                                , Border.width 1
                                                , Font.size 17
                                                ]
                                )
                in
                [ renderPow key.parts
                    |> el [ Font.size (fork model.isMobile 11 15) ]
                , [ tierLabel
                  , downloadAs
                        [ hover
                        , padding 5
                        , Background.color white
                        , Border.rounded 5
                        , Border.width 1
                        , Font.size 17
                        ]
                        { label = text "Save Key  💾"
                        , filename = key.pubkey ++ ".json"
                        , url =
                            key.bytes
                                |> JE.list JE.int
                                |> JE.encode 0
                                |> Url.percentEncode
                                |> (++) "data:text/json;charset=utf-8,"
                        }
                  ]
                    |> row [ alignRight, spacing 10 ]
                ]
                    |> column
                        [ spacing 10
                        , Border.width 1
                        , width fill
                        , padding 10
                        , Background.color green
                        , Border.rounded 5
                        ]
            )
        |> column
            [ spacing 5
            , height fill
            , scrollbarY
            , width fill
            , [ spinner 30
                    |> el [ centerX, padding 10 ]
              , para
                    [ Font.center
                    , Font.size 16
                    , paddingXY 20 0
                    ]
                    "This may take some time, consider using the Solana keygen CLI for faster results."
              , text "More instructions"
                    |> btn (Just (SetView ViewAvails))
                        [ Font.underline
                        , centerX
                        , Font.size 16
                        ]
              ]
                |> column [ spacing 20, centerX ]
                |> inFront
                |> whenAttr (List.isEmpty model.keys && model.grinding)
            ]
    , [ [ text "Results:"
            |> el [ Font.bold ]
        , text (String.fromInt (List.length model.keys))
        ]
            |> row [ spacing 10 ]
      , [ text "Keys checked:"
            |> el [ Font.bold ]
        , text <| formatKeycount model.count
        ]
            |> row [ spacing 10 ]
      , [ text "KPS:"
            |> el [ Font.bold ]
        , text
            ((kps model.count model.startTime model.now
                |> (\n -> n / 1000)
                |> formatFloat
             )
                ++ "k"
            )
        ]
            |> row [ spacing 10 ]
      ]
        |> List.intersperse (text "|")
        |> row [ width fill, spaceEvenly, Font.size (fork model.isMobile 11 15), blockFont ]
        |> when (model.count > 0)
    ]
        |> column
            [ spacing 10
            , height fill
            , scrollbarY
            , width fill
            ]


viewInfo _ =
    [ [ text ("POW " ++ bang)
            |> el [ titleFont ]
      , text " is a free mint that requires "
            |> el [ paddingXY 5 0 ]
      , text "WORK"
            |> el [ titleFont ]
      ]
        |> paragraph [ Font.size 24, mainFont, Font.center ]
    , (bang ++ "  MINT NOW!")
        |> para
            [ comicFont
            , Font.size 28
            , padding 10
            , Border.width 1
            , Background.color green
            ]
        |> btn (Just (SetView ViewMint))
            [ centerX
            , style "animation" "pulse 2s infinite"
            ]
    , [ ( bang
        , [ text "Every POW NFT has a unique number ID that can only be minted once."
          ]
            |> paragraph []
        )
      , ( "⚡"
        , [ text "Claiming each POW requires generating a "
          , text "Solana keypair"
                |> linkOut "https://docs.solana.com/wallet-guide" [ Font.underline ]
          , text " that contains the ID in a specific format."
          ]
            |> paragraph []
        )
      , ( "⚙️"
        , [ text "These keys can be generated by anyone using the official "
          , text "'solana-keygen' tool"
                |> linkOut "https://www.quicknode.com/guides/solana-development/getting-started/how-to-create-a-custom-vanity-wallet-address-using-solana-cli"
                    [ Font.underline ]
          , text "."
          ]
            |> paragraph []
        )
      , ( "💻"
        , para [] "All minting will be done on this site. All mints are free."
        )
      , ( "💎"
        , [ text "POW NFTs will be assigned tiers based on their difficulty to generate. The longer the number ID, the higher the tier." ]
            |> paragraph []
        )
      , ( "🎨"
        , [ text "Each POW tier will have a different piece of placeholder art. A future generative art reveal is planned, with unique PFPs for every NFT." ]
            |> paragraph []
        )
      , ( "🌌"
        , text "What is the Tier Z / Anomaly trait?"
            |> linkOut "https://twitter.com/pow_mint/status/1756766034285977829"
                [ Font.underline ]
        )
      ]
        |> List.map
            (\( icn, elem ) ->
                [ text icn
                    |> el [ Font.size 25, alignTop ]
                , elem
                ]
                    |> row [ spacing 20 ]
            )
        |> column [ width fill, spacing 25, Font.size 17 ]
    ]
        |> column
            [ spacing 30
            , height fill
            , scrollbarY
            ]


viewMint model =
    let
        select =
            Html.input
                [ Html.Attributes.type_ "file"
                , Html.Events.on "change"
                    (JD.map FileCb
                        (JD.at
                            [ "target", "files", "0" ]
                            JD.value
                        )
                    )
                , Html.Attributes.style "padding" "5px"
                , Html.Attributes.style "cursor" "pointer"
                ]
                []
                |> Element.html
                |> el
                    [ hover
                    , Background.color green
                    , Border.rounded 5
                    , Border.width 2
                    ]
    in
    [ model.loadedKeypair
        |> unwrap
            (if model.walletInUse then
                [ text "Keypair loading"
                , spinner 30
                    |> el [ centerX ]
                ]
                    |> column [ spacing 20 ]

             else
                [ text (bang ++ "  POW NFT Mint")
                    |> el [ Font.bold, centerX ]
                , para [] "You will need to provide a Solana keypair file that begins with 'pow', followed by a number."
                , [ text "Examples:"
                        |> el [ Font.italic ]
                  , renderPowLink model.isMobile
                        [ "pow"
                        , "985"
                        , "Q4pDoFu2717KWq9otDP6chkiTdXbb2B7eKAwo"
                        ]
                  , renderPowLink model.isMobile
                        [ "pow"
                        , "4269"
                        , "mWh13DW3DvgBTuZyA33gr1KX2GcsQMhXumgX"
                        ]
                  , renderPowLink model.isMobile
                        [ "pow"
                        , "56136"
                        , "HjhNPQZfTujY9c4Ecr8GPFGM1vXm1T6GMc5"
                        ]
                  ]
                    |> column
                        [ spacing 10
                        , Border.width 1
                        , padding 10
                        , Font.size 16
                        ]
                , select
                ]
                    |> column [ spacing 20, width fill ]
            )
            (viewKeypair model)
    , model.keypairMessage
        |> whenJust
            (\txt ->
                text
                    ("⚠️  " ++ txt)
            )
    ]
        |> column
            [ spacing 30
            , width fill
            ]


viewKeypair model key =
    [ [ [ text "Solana keypair loaded"
        , text "Cancel"
            |> btn (Just Reset) [ Font.underline ]
        ]
            |> row
                [ width fill
                , spaceEvenly
                , Background.color navy
                , Font.color beige
                , padding 10
                ]
      , renderPow key.parts
            |> el
                [ paddingXY 15 10
                , Font.size 15
                ]
      ]
        |> column
            [ spacing 0
            , Border.width 1
            , Border.rounded 7
            , Background.color white
            ]
    , case model.mintSig of
        Just sig ->
            [ text "Success!"
                |> el [ centerX ]
            , nftLink key.pubkey
                |> el [ Font.underline ]
            , newTabLink [ hover, Font.underline ]
                { url =
                    "https://solscan.io/tx/"
                        ++ sig
                , label = text "View transaction"
                }
            ]
                |> column [ spacing 20, centerX ]

        Nothing ->
            key.nft
                |> unwrap
                    ([ text "Not a valid POW NFT keypair."
                     ]
                        |> column
                            [ Font.italic
                            , width <| px 500
                            , spacing 20
                            ]
                    )
                    (\nft ->
                        let
                            idStr =
                                String.fromInt nft.id
                        in
                        if model.keypairCheck.inProg then
                            spinner 30
                                |> el [ centerX ]

                        else
                            model.keypairCheck.mint
                                |> unwrap
                                    (text "There was a problem.")
                                    (unwrap
                                        (if List.member nft.tier haltedTiers then
                                            [ text ("POW #" ++ idStr)
                                                |> el [ Font.size 22, centerX, Font.bold ]
                                            , para [ Font.center ]
                                                ("Minting of Tier "
                                                    ++ String.fromInt nft.tier
                                                    ++ " NFTs is closed. Please save this Keypair, it can be used in a future proof-of-work verification."
                                                )
                                            ]
                                                |> column [ spacing 20 ]

                                         else if nft.id > u32_MAX then
                                            "The maximum possible ID is "
                                                ++ String.fromInt u32_MAX
                                                ++ "."
                                                |> text

                                         else
                                            [ text ("POW #" ++ idStr ++ " is available!")
                                                |> el [ Font.size 22, centerX ]
                                            , model.wallet
                                                |> unwrap
                                                    ([ text "Connect a Solana wallet to continue"
                                                     , selectWallet
                                                        |> el [ centerX ]
                                                     ]
                                                        |> column [ spacing 20 ]
                                                    )
                                                    (\_ ->
                                                        [ text ("💥  Mint POW #" ++ idStr)
                                                        , spinner 15
                                                            |> when model.walletInUse
                                                        ]
                                                            |> row [ spacing 10 ]
                                                            |> btn (Just (MintNft key.bytes))
                                                                [ Border.width 1
                                                                , padding 10
                                                                , Border.rounded 5
                                                                , Background.color white
                                                                ]
                                                    )
                                                |> el [ centerX ]
                                            ]
                                                |> column [ spacing 20, centerX ]
                                        )
                                        (viewClaimedPOW nft.id)
                                    )
                    )
    ]
        |> column [ spacing 20 ]


viewAvails model =
    [ para [ Font.bold ] "Find your next POW NFT!"
    , [ para [ Font.italic ] "Enter an NFT ID to check if it is available:"
      , [ Input.text
            [ width <| px 170
            , Html.Attributes.type_ "number"
                |> htmlAttribute
            , Html.Attributes.min "1"
                |> htmlAttribute
            , Html.Attributes.max "4294967295"
                |> htmlAttribute
            , onKeydown "Enter" SubmitId
                |> whenAttr (not model.idCheck.inProg)
            ]
            { label = Input.labelHidden ""
            , onChange = IdInputChange
            , placeholder =
                text "12345"
                    |> Input.placeholder []
                    |> Just
            , text = model.idInput
            }
        , text "Check id"
            |> baseBtn
                (if model.idCheck.inProg then
                    Nothing

                 else
                    Just SubmitId
                )
                [ spinner 20
                    |> el [ centerY, paddingXY 10 0 ]
                    |> onRight
                    |> whenAttr model.idCheck.inProg
                ]
        ]
            |> row [ spacing 20 ]
      , model.searchMessage
            |> whenJust
                (\txt ->
                    para [ Font.italic ]
                        ("⚠️  " ++ txt)
                )
      ]
        |> column [ spacing 20 ]
    , if model.idCheck.inProg then
        none

      else
        model.idCheck.id
            |> whenJust
                (\id ->
                    let
                        idStr =
                            String.fromInt id

                        tier =
                            String.length idStr
                    in
                    model.idCheck.mint
                        |> unwrap
                            (text "There was a problem.")
                            (unwrap
                                (if List.member tier haltedTiers then
                                    para [ Font.center ]
                                        ("Minting of Tier "
                                            ++ String.fromInt tier
                                            ++ " NFTs is closed. This POW ID was not minted."
                                        )

                                 else
                                    [ text ("POW #" ++ idStr ++ " is available!")
                                        |> el [ Font.size 22, centerX ]
                                    , text "Get it by using:"
                                    , "solana-keygen grind --starts-with pow"
                                        ++ idStr
                                        ++ ":1"
                                        |> text
                                        |> el
                                            [ paddingXY 20 15
                                            , Background.color beige
                                            , Font.size 16
                                            ]
                                    , newTabLink [ Font.underline, hover ]
                                        { url = "https://docs.solana.com/cli/install-solana-cli-tools"
                                        , label = text "Installation guide"
                                        }
                                    , [ text "Estimated duration on a laptop:"
                                      , text
                                            (case String.length idStr + 3 of
                                                4 ->
                                                    "<1 minute"

                                                5 ->
                                                    "~26 minutes"

                                                6 ->
                                                    "~25 hours"

                                                7 ->
                                                    "~1470 hours"

                                                8 ->
                                                    "~9 years"

                                                _ ->
                                                    "Forever"
                                            )
                                      ]
                                        |> row [ spacing 10 ]
                                        |> when False
                                    , text ("Or use the generator tool " ++ bang)
                                        |> btn (Just (SetViewGen True)) [ Font.underline ]
                                    ]
                                        |> column [ spacing 20 ]
                                )
                                (viewClaimedPOW id)
                            )
                )
    ]
        |> column
            [ spacing 20
            , height fill
            , scrollbarY
            ]


viewClaimedPOW : Int -> String -> Element msg
viewClaimedPOW id mint =
    [ para [ Font.size 20, Font.italic ] ("POW #" ++ String.fromInt id ++ " has already been claimed.")
    , nftLinkWTensor mint
    ]
        |> column [ spacing 20 ]


viewBanner model =
    [ [ text "$"
            |> el [ Font.color gold ]
      , text "solana-keygen grind"
      ]
        |> row
            [ Font.size (fork model.isMobile 17 22)
            , blockFont
            , spacing 8
            ]
        |> when (not model.isShort)
    , model.demoAddress
        |> List.indexedMap
            (\n txt_ ->
                String.split "" txt_
                    |> List.map
                        (\txt ->
                            if n == 0 then
                                text txt

                            else if n == 1 then
                                text txt
                                    |> el
                                        [ Font.bold
                                        , Font.size (fork model.isMobile 17 22)
                                        , Font.color red
                                        ]

                            else
                                text txt
                        )
            )
        |> List.concat
        |> row
            [ width fill
            , spaceEvenly
            , blockFont
            , Font.size (fork model.isMobile 13 15)
            ]
    ]
        |> column
            [ spacing 15
            , Font.color white
            , Background.color black
            , padding 10

            --, width (fork model.isMobile fill (px 550))
            , width fill
            ]


shadow =
    Border.shadow
        { blur = 0
        , color = black
        , offset = ( 3, 3 )
        , size = 2
        }


monospaceFont =
    Font.family [ Font.monospace ]


comicFont =
    Font.family [ Font.typeface "Bangers" ]


titleFont =
    Font.family [ Font.typeface "Bowlby One SC" ]


blockFont =
    Font.family [ Font.typeface "IBM Plex Mono" ]


mainFont =
    Font.family [ Font.typeface "Montserrat Variable" ]


btn : Maybe msg -> List (Attribute msg) -> Element msg -> Element msg
btn msg attrs elem =
    Input.button
        ((if msg == Nothing then
            []

          else
            [ hover ]
         )
            ++ attrs
        )
        { onPress = msg
        , label = elem
        }


baseBtn : Maybe msg -> List (Attribute msg) -> Element msg -> Element msg
baseBtn msg attrs =
    btn msg
        (attrs
            ++ [ padding 10
               , Border.width 1
               , Border.rounded 5
               , Background.color green
               , Border.shadow
                    { blur = 0
                    , color = black
                    , offset = ( 2, 2 )
                    , size = 1
                    }
               ]
        )


fade : Element.Attr a b
fade =
    Element.alpha 0.6


hover : Attribute msg
hover =
    Element.mouseOver [ fade ]


navBtn v txt v_ =
    let
        active =
            v == v_
    in
    text txt
        |> btn
            (if active then
                Nothing

             else
                Just (SetView v_)
            )
            [ Background.color
                (if active then
                    white

                 else
                    navy
                )
            , Font.color
                (if active then
                    navy

                 else
                    white
                )
            , Border.color navy
            , paddingXY 20 10
            , Border.roundEach
                { topRight = 10
                , bottomLeft = 0
                , bottomRight = 0
                , topLeft = 0
                }
            ]


renderPowLink trunc parts =
    renderPowTrunc parts trunc
        |> linkOut
            ("https://solscan.io/account/"
                ++ String.concat parts
            )
            []


renderPow addr =
    renderPowTrunc addr False


renderPowTrunc addr trunc =
    addr
        |> List.indexedMap
            (\n txt ->
                if n == 0 then
                    text txt

                else if n == 1 then
                    text txt
                        |> el
                            [ Font.bold
                            ]

                else
                    text
                        (if trunc then
                            String.left 15 txt ++ "..."

                         else
                            txt
                        )
            )
        |> row
            [ spacing 1
            ]


spinner : Int -> Element msg
spinner n =
    Img.notch n
        |> el [ spinAttr ]


nftLink mint =
    newTabLink [ hover, Font.underline ]
        { url =
            "https://solscan.io/token/"
                ++ mint
        , label = text "🔍 View NFT"
        }


nftLinkWTensor mint =
    [ nftLink mint
    , text "|"
    , newTabLink [ hover, Font.underline ]
        { url =
            "https://tensor.trade/item/"
                ++ mint
        , label = text "Bid on Tensor 🎯"
        }
    ]
        |> row [ spacing 15 ]


tensorLink =
    newTabLink [ hover, Font.underline ]
        { url = "https://www.tensor.trade/trade/pow"
        , label = text "⚡ Buy on Tensor"
        }


viewX =
    newTabLink
        [ Background.color white
        , shadow
        , blockFont
        , hover
        , paddingXY 15 10
        , Font.size 17
        ]
        { url = "https://x.com/pow_mint"
        , label =
            [ Img.x 17
            , text "@pow_mint"
            ]
                |> row [ spacing 10 ]
        }


fadeIn =
    style "animation" "fadeIn 1s"


viewNavMobile model =
    navContent
        |> List.drop 1
        |> List.map
            (\( txt, v_ ) ->
                let
                    active =
                        v == v_

                    v =
                        model.view
                in
                text txt
                    |> btn
                        (if active then
                            Nothing

                         else
                            Just (SetView v_)
                        )
                        [ Background.color
                            (if active then
                                white

                             else
                                navy
                            )
                        , Font.color
                            (if active then
                                navy

                             else
                                white
                            )
                        , Border.color navy
                        , paddingXY 10 10
                        , Border.rounded 10
                        , Font.size 13
                        ]
            )
        |> row
            [ spaceEvenly
            , width fill
            ]


viewNav model =
    navContent
        |> List.map
            (\( k, v ) ->
                navBtn model.view k v
            )
        |> row
            [ spacing 10
            , width fill
            , Font.size (fork model.isMobile 16 19)
            ]


navContent =
    [ ( "🏠", ViewHome )
    , ( "Search 🔍", ViewAvails )
    , ( "Grind 🎰", ViewGenerator )
    , ( "Mint " ++ bang, ViewMint )
    , ( "Holders 💎", ViewHolder )
    ]


bang =
    String.fromChar '💥'


emTarget =
    String.fromChar '🎯'


fork bool a b =
    if bool then
        a

    else
        b


linkOut url attrs elem =
    newTabLink
        (hover :: attrs)
        { url = url
        , label = elem
        }


para attrs =
    text >> List.singleton >> paragraph attrs


spinAttr : Attribute msg
spinAttr =
    style "animation" "rotation 0.7s infinite linear"


title val =
    Html.Attributes.title val
        |> htmlAttribute


kps : Int -> Int -> Int -> Float
kps txsCount startTime currentTime =
    let
        elapsedTimeInSeconds =
            toFloat (currentTime - startTime) / 1000
    in
    toFloat txsCount / elapsedTimeInSeconds


formatFloat =
    FormatNumber.format
        { usLocale
            | decimals = FormatNumber.Locales.Exact 2
        }


formatRound =
    round
        >> toFloat
        >> FormatNumber.format
            { usLocale
                | decimals = FormatNumber.Locales.Exact 0
            }


formatBillion : BigInt.BigInt -> String
formatBillion amount =
    let
        bil =
            BigInt.fromInt 1000000000

        mil =
            BigInt.fromInt 1000000
    in
    if BigInt.lt amount mil then
        "<1m"

    else if BigInt.lt amount bil then
        (BigInt.div amount mil
            |> BigInt.toString
            |> String.toInt
            |> Maybe.withDefault 999
            |> toFloat
            |> FormatNumber.format
                { usLocale
                    | decimals = FormatNumber.Locales.Exact 0
                }
        )
            ++ "m"

    else
        (BigInt.div amount bil
            |> BigInt.toString
            |> String.toInt
            |> Maybe.withDefault 999
            |> toFloat
            |> FormatNumber.format
                { usLocale
                    | decimals = FormatNumber.Locales.Exact 0
                }
        )
            ++ "bn"


formatMils : Int -> String
formatMils amount_ =
    let
        amount =
            toFloat amount_

        mil =
            1000000.0

        bil =
            1000000000.0
    in
    if amount == 0 then
        "0m"

    else if amount < 100000 then
        ">0.1m"

    else if amount < mil then
        formatFloat (amount / 1000) ++ "k"

    else if amount < bil then
        formatFloat (amount / mil) ++ "m"

    else
        (amount
            / bil
            |> formatFloat
        )
            ++ "bn"


selectWallet =
    [ Img.solana 20, text "Select Wallet" ]
        |> row
            [ spacing 15
            , Font.size 20
            , paddingXY 25 15
            , monospaceFont
            , Font.bold
            , style "animation" "all 1s"
            ]
        |> btn (Just SelectWallet)
            [ Background.gradient
                { angle = degrees 170
                , steps =
                    [ black, black, rgb255 128 0 128 ]
                }
            , Font.color white
            , mouseOver
                [ Background.gradient
                    { angle = degrees 350
                    , steps =
                        [ black, black, rgb255 128 0 128 ]
                    }
                , Border.color black
                ]
            , Border.rounded 10
            , Border.width 2
            , Border.color red
            ]


formatKeycount n =
    if n > 1000000 then
        formatFloat (toFloat (n // 1000) / 1000) ++ "m"

    else
        String.fromInt (n // 1000) ++ "k"


viewMemescan : Model -> Bool -> Element Msg
viewMemescan model utilityAccess =
    let
        poolsPresent =
            Dict.isEmpty model.pools
                |> not

        viewBulb col txt =
            [ el
                [ Background.color col
                , height <| px 20
                , width <| px 20
                , Border.rounded 10
                , style "animation" "pulse-border 1.5s infinite"
                    |> whenAttr (txt == "LIVE")
                ]
                none
            , text txt
                |> el [ Font.bold ]
            ]
                |> row [ spacing 10 ]

        titleElem =
            let
                txt =
                    emTarget ++ "  Memecoin Liquidity Tracker"
            in
            if model.isMobile then
                para [ Font.size 18, Font.bold ] txt

            else
                text txt
                    |> el [ Font.bold, Font.size 22 ]

        backElem =
            text "↩️  Back to inventory"
                |> btn (Just ToggleUtility) [ Font.underline ]

        connectElem =
            text "📡  Connect"
                |> baseBtn
                    (if model.wsConnectInProgress then
                        Nothing

                     else
                        Just WsConnect
                    )
                    [ spinner 15
                        |> el [ centerY, paddingXY 10 0 ]
                        |> onRight
                        |> whenAttr model.wsConnectInProgress
                    ]
    in
    if poolsPresent then
        [ [ [ titleElem
            , text "Live pool updates from Raydium"
                |> when (not model.isMobile)
            ]
                |> column
                    [ spacing 10
                    , width fill
                        |> whenAttr model.isMobile
                    ]
          , case model.wsStatus of
                Standby ->
                    [ viewBulb (rgb255 255 0 0) "OFFLINE"
                    , connectElem
                        |> el [ Font.size 15 ]
                    ]
                        |> fork model.isMobile column row [ spacing 10 ]
                        |> when poolsPresent

                Connecting ->
                    spinner 40

                Live ->
                    [ viewBulb (rgb255 0 255 0) "LIVE"
                    , text "❌  Disconnect"
                        |> btn (Just WsDisconnect)
                            [ Font.underline
                            , Font.size 12
                            , alignRight
                            ]
                    ]
                        |> column [ spacing 10 ]
          ]
            |> row [ width fill, spaceEvenly ]
        , if Dict.isEmpty model.pools then
            spinner 40
                |> el [ centerX ]

          else
            model.pools
                |> Dict.values
                |> List.sortBy (\x -> x.openTime)
                |> List.reverse
                |> List.map (viewPool model)
                |> column [ spacing 40, width fill, height fill, scrollbarY ]
        , [ backElem
          , text "🧹  Clear results"
                |> btn (Just ClearResults) [ Font.underline ]
                |> when (poolsPresent && model.wsStatus == Standby)
          ]
            |> row [ spacing 20, alignRight, Font.size 16 ]
        ]
            |> column [ spacing 20, width fill, height fill ]

    else
        [ para [ Font.bold, Font.size 22, Font.center ]
            (emTarget ++ "  Memecoin Liquidity Tracker")
        , para [ Font.center, cappedWidth 400, centerX ]
            "This tool tracks all new memecoin liquidity pools created on Raydium, and displays them alongside real-time token analysis such as holder composition, mint authority status etc."
        , if utilityAccess then
            connectElem
                |> el [ centerX ]

          else
            [ text "🚫  No Access"
                |> el [ centerX ]
            , para [ Font.italic, Font.size 15 ] "You need to hold more POW NFTs."
            , tensorLink
                |> el [ centerX, Font.size 15 ]
            ]
                |> column [ spacing 20, centerX, padding 10, Border.width 1 ]
        , backElem
            |> el [ centerX ]
        ]
            |> column [ spacing 30, paddingXY 0 30, centerX ]
            |> el [ height fill, width fill ]


viewPool model hit =
    let
        axis =
            if model.isMobile then
                column [ width fill, spacing 10 ]

            else
                row [ width fill, spaceEvenly ]

        rugged =
            hit.reserve < 0.5
    in
    [ [ [ text "POOL"
            |> el [ Font.bold ]
        , text (String.left 8 hit.pool ++ "...")
            |> el [ Font.size 15 ]
        ]
            |> row
                [ spacing 10
                ]
            |> linkOut ("https://solscan.io/account/" ++ hit.pool)
                [ Background.color black
                , Font.color white
                , padding 10
                ]
      , text
            (if rugged then
                "⚠️ RUGGED"

             else
                "⏰ " ++ formatTime model.now hit.openTime
            )
            |> el
                [ paddingXY 10 0
                , monospaceFont
                , Font.size (fork model.isMobile 15 19)
                ]
      ]
        |> row [ width fill, spaceEvenly ]
    , [ [ [ text (truncateText 22 hit.name)
                |> el [ Font.size 22, title hit.name ]
          , text hit.symbol
                |> el [ Font.bold, Font.size 15 ]
          , text "📋"
                |> btn (Just (Copy hit.mint))
                    [ title hit.mint
                    ]
          ]
            |> (if model.isMobile then
                    wrappedRow [ width fill, spacing 10 ]

                else
                    row [ spacing 10 ]
               )
        , text "Refresh"
            |> btn (Just (RefreshPool hit.pool))
                [ Font.underline
                , Font.size 14
                ]
            |> when False
        , viewBubble "Mint" hit.mint
        ]
            |> axis
      , [ viewTag "Supply"
            (hit.mintSupply
                |> round
                |> BigInt.fromInt
                |> formatBillion
            )
        , viewTag "Mint Disabled"
            (if hit.mintLocked then
                "✅"

             else
                "❌"
            )
        ]
            |> axis
      , [ viewTag "Price" ("$" ++ formatTinyPrice hit.price)
        , viewTag "Market Cap" ("$" ++ formatFloat (hit.price * hit.mintSupply * model.solPrice))
        ]
            |> axis
      , [ viewTag "Holders" (String.fromInt hit.holders)
        , [ viewTag "Top 10" (formatRound hit.top10 ++ "%")
          , viewTag "Top 20" (formatRound hit.top20 ++ "%")
          ]
            |> axis
        ]
            |> column [ width fill, spacing 10, padding 10, Border.width 1 ]
            |> when False
      , [ [ viewBubble "Raydium Pool" hit.pool
          , viewBubble "LP Mint" hit.lpMint
          ]
            |> axis
        , [ viewTag "SOL reserve" (formatFloat hit.reserve)
          , viewTag "Pool Age" (formatTime model.now hit.openTime)
          ]
            |> axis
        , [ viewTag "Liquidity Burned"
                (if hit.liquidityLocked then
                    "✅"

                 else
                    "❌"
                )
          , viewTag "Supply In Pool" (formatRound hit.inPool ++ "%")
          ]
            |> axis
        ]
            |> column [ width fill, spacing 10, padding 10, Border.width 1 ]
      , [ newTabLink [ hover, Font.size 15, Font.underline ]
            { url =
                "https://birdeye.so/token/" ++ hit.mint ++ "?chain=solana"
            , label = text "Birdeye"
            }
        , newTabLink [ hover, Font.size 15, Font.underline ]
            { url =
                "https://dexscreener.com/solana/"
                    ++ hit.mint
            , label = text "Dexscreener"
            }
        , newTabLink [ hover, Font.size 15, Font.underline ]
            { url =
                "https://raydium.io/swap/?inputCurrency=sol&outputCurrency=" ++ hit.mint
            , label = text "Swap on Raydium"
            }
        ]
            |> (if model.isMobile then
                    row [ width fill, spaceEvenly ]

                else
                    row [ centerX, spacing 30 ]
               )
      ]
        |> column [ width fill, spacing 20, padding 10 ]
    ]
        |> column
            [ width fill
            , Border.width 1
            , shadow
            , fadeIn
            ]


formatTinyPrice fl =
    let
        str =
            if fl > 0.000001 then
                String.fromFloat fl

            else
                fl
                    |> Float.Extra.toFixedSignificantDigits 200

        chars =
            str
                |> String.split "."
                |> List.drop 1
                |> List.head
                |> Maybe.withDefault "ok"
                |> String.toList

        zeroes =
            chars
                |> List.Extra.takeWhile ((==) '0')
                |> List.length

        suff =
            List.drop zeroes chars
                |> List.take 3
                |> String.fromList
    in
    if zeroes < 4 then
        Float.Extra.toFixedSignificantDigits 3 fl

    else
        "0.0(" ++ String.fromInt zeroes ++ ")" ++ suff


truncateText n txt =
    let
        len =
            String.length txt
    in
    if len > n then
        String.left (n - 3) txt ++ "..."

    else
        txt


ellipsisText : Int -> String -> Element msg
ellipsisText n txt =
    Html.div
        [ Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "height" <| String.fromInt n ++ "px"
        , Html.Attributes.style "display" "table-cell"
        , Html.Attributes.title txt
        ]
        [ Html.text txt
        ]
        |> Element.html
        |> el
            [ width fill
            , style "table-layout" "fixed"
            , style "display" "table"
            , Font.size n
            ]


powLogo size =
    image
        [ height <| px size
        , style "animation" "pulse 2s infinite"
        ]
        { src = "/pow.png"
        , description = ""
        }
