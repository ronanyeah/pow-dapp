module View exposing (view)

import Colors exposing (..)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FormatNumber
import FormatNumber.Locales exposing (usLocale)
import Helpers.View exposing (cappedHeight, cappedWidth, onKeydown, style, when, whenAttr, whenJust)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Img
import Json.Decode as JD
import Json.Encode as JE
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

            --, Background.color Colors2.greenDarnerTail
            , Background.gradient
                { angle = degrees 30
                , steps =
                    [ lightBlue
                    , lightPurple
                    , lightPurple

                    --, lightPurple
                    , lightBlue

                    --, lightPurple
                    , lightPurple
                    , lightPurple
                    , lightBlue
                    , lightPurple
                    , lightPurple
                    , lightBlue

                    --
                    --rgba255 34 0 51 0.9
                    --, rgba255 17 0 34 0.9
                    --, rgba255 68 0 102 0.9
                    --, rgba255 34 0 51 0.9
                    ]
                        |> List.reverse
                }

            --, Background.image "/bg.png"
            ]


viewWide : Model -> Element Msg
viewWide model =
    let
        logo =
            image
                [ height <| px (fork model.isMobile 170 250)
                , style "animation" "pulse 2s infinite"
                ]
                { src = "/pow.png"
                , description = ""
                }
    in
    [ [ [ image [ height <| px 100 ]
            { src = "/bang.png"
            , description = ""
            }
        , text "POW"
            |> el [ titleFont, Font.size 65 ]
        ]
            |> row [ centerX, spacing 20 ]
            |> when False

      --, [ text "The world's first proof-of-work NFT"
      --]
      --|> paragraph
      --[ width <| px 300
      --, Border.shadow
      --{ blur = 0
      --, color = black
      --, offset = ( 2, 2 )
      --, size = 2
      --}
      --, centerX
      --, Font.size 19
      --, alignBottom
      --, alignRight
      --, Background.color white
      --, padding 5
      --, moveRight 200
      --, moveUp 20
      --]
      --|> inFront
      , [ logo
        , [ text "FREE MINT"
                |> el []
                |> wrapBox

          --, text "XXth JANUARY"
          , text "JANUARY 2024"
                |> el []
                |> wrapBox
          , [ Img.solana 20
            , text "SOLANA"
                |> el []
            ]
                |> row [ spacing 10 ]
                |> wrapBox
          ]
            |> column [ spacing 10, Font.size 15 ]
            |> when False
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
          , viewX
                |> el [ centerX ]
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
                model.viewGen
                    |> unwrap
                        ([ para
                            [ Font.center
                            , Font.size 25
                            ]
                            "Welcome to the POW keypair generator!"
                         , para [ Font.center, Font.italic ] "What do you want to do?"
                         , text "Generate a POW NFT"
                            |> btn (Just (SetViewGen True)) [ padding 10, Border.width 1, centerX ]
                         , text "Generate a Solana vanity wallet"
                            |> btn (Just (SetViewGen False)) [ padding 10, Border.width 1, centerX ]
                         ]
                            |> column [ spacing 30, width fill, paddingXY 0 40 ]
                        )
                        (viewGenerator model)

            ViewMint ->
                viewMint model

            ViewAvails ->
                viewAvails model
        )
            |> el
                [ Background.color white
                , paddingXY (fork model.isMobile 15 30) 20
                , shadow
                , height fill
                , width fill
                ]

      --, viewGenerator model
      --, viewPanel model
      --|> el [ centerX, width fill ]
      ]
        |> column
            [ height fill
            , fadeIn
            , width fill
            ]
    ]
        |> row
            [ width <| px 1150
            , spaceEvenly
            , centerX
            , height fill
            , cappedHeight 800
            , padding 30
            , spacing 30
            ]


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
        6534
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
        3
        Nothing
        InProgress
        [ "pow"
        , "537113567"
        , "RAdU8GRzPjsZDB3sHn2RqFa82yki4ph"
        ]
    , viewMintRow 10
        0
        Nothing
        InProgress
        []
    , para [ Font.italic, Font.size 14 ] "Note: '0' is not a valid character in Solana addresses, so cannot be in a POW ID."
    ]
        |> column
            [ spacing 10
            , padding 10
            , Background.color white
            , width fill
            , Font.size 15
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
    , if List.isEmpty addr then
        text "???"

      else
        newTabLink [ hover, Font.size 15 ]
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
        logo =
            image
                [ height <| px (fork model.isMobile 170 250)
                , style "animation" "pulse 2s infinite"
                ]
                { src = "/pow.png"
                , description = ""
                }
    in
    [ [ image [ height <| px 100 ]
            { src = "/bang.png"
            , description = ""
            }
      , text "POW"
            |> el [ titleFont, Font.size 65 ]
      ]
        |> row [ centerX, spacing 20 ]
        |> when False

    --, [ text "The world's first proof-of-work NFT"
    --]
    --|> paragraph
    --[ width <| px 300
    --, Border.shadow
    --{ blur = 0
    --, color = black
    --, offset = ( 2, 2 )
    --, size = 2
    --}
    --, centerX
    --, Font.size 19
    --, alignBottom
    --, alignRight
    --, Background.color white
    --, padding 5
    --, moveRight 200
    --, moveUp 20
    --]
    --|> inFront
    , [ logo
      , [ text "FREE MINT"
            |> el []
            |> wrapBox

        --, text "XXth JANUARY"
        , text "JANUARY 2024"
            |> el []
            |> wrapBox
        , [ Img.solana 20
          , text "SOLANA"
                |> el []
          ]
            |> row [ spacing 10 ]
            |> wrapBox
        ]
            |> column [ spacing 10, Font.size 15 ]
            |> when False
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
        , viewX
            |> el [ centerX ]
        ]
            |> column
                [ cappedWidth (fork model.isMobile 160 250)
                , spacing 20
                ]
      ]
        |> row [ spacing 10, centerX ]

    --, model.demoAddress
    --|> List.indexedMap
    --(\n txt ->
    --if n == 0 then
    --text txt
    --else if n == 1 then
    --text txt
    --|> el
    --[ Font.bold
    --, Font.size 22
    --]
    --else
    --text txt
    --)
    --|> row [ centerX, spacing 1 ]
    , [ viewNav model
      , case model.view of
            ViewHome ->
                viewInfo model

            ViewGenerator ->
                --viewGenerator model
                text "mint"

            ViewMint ->
                viewMint model

            ViewAvails ->
                text "avails"
      ]
        |> column [ width fill, height fill ]

    --, viewGenerator model
    --, viewPanel model
    --|> el [ centerX, width fill ]
    , viewBanner model
        |> el
            [ fork model.isMobile (width fill) centerX
            , alignBottom
            ]
        |> when (model.view == ViewHome)
    ]
        |> column
            [ padding
                (fork model.isMobile 20 25)
            , spacing
                (fork model.isMobile 20 25)
            , height fill
            , fork model.isMobile (width fill) centerX
            , fadeIn
            , scrollbarY
                |> whenAttr model.isMobile
            ]


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

                --text "12345"
                --|> Input.placeholder []
                --|> Just
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
            , label =
                --viewH2 label |> Input.labelAbove []
                Input.labelHidden ""
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

                    --, Input.text
                    --[ width <| px 150
                    --]
                    --{ label =
                    --text "Contains"
                    --|> Input.labelAbove []
                    --, onChange = ContainChange
                    --, placeholder = Nothing
                    --, text = model.containInput
                    --}
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
                    canMint =
                        key.nft
                            |> unwrap False
                                (\nft ->
                                    Dict.get nft.id model.nftExists
                                        |> unwrap True not
                                )
                in
                [ renderPow key.parts
                    |> el [ Font.size (fork model.isMobile 11 15) ]
                , [ text "Mint Now 💥"
                        |> btn (Just (SelectNft key))
                            [ padding 5
                            , Background.color white
                            , Border.rounded 5
                            , Border.width 1
                            , Font.size 17
                            ]
                        |> when canMint
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

            --, Background.color green
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
    [ text ("MINT GUIDE   " ++ bang)
        |> el [ centerX, Font.size 35, comicFont ]
        |> when False

    --, [ text "POW is a free mint with a twist." ]
    , [ text ("POW " ++ bang)
            |> el [ titleFont ]
      , text " is a free mint that requires "
            |> el [ paddingXY 5 0 ]
      , text "WORK"
            |> el [ titleFont ]
      ]
        |> paragraph [ Font.size 24, mainFont, Font.center ]
    , "MINT NOW!"
        |> para [ comicFont, Font.size 28, padding 10, Border.width 1 ]
        |> btn (Just (SetView ViewMint))
            [ centerX
            , style "animation" "pulse 2s infinite"
            ]

    --, [ ( bang
    --, para [] "POW is a free mint with a twist."
    --)
    , [ ( bang
          --, para [] "Every NFT requires the degen to generate a specific solana keypair. These can be created with the 'solana-keygen' tool."
          --, [ text "Every POW NFT requires a specific solana keypair to mint. These can be created by anyone using the "
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


viewPanel model =
    [ [ navBtn model.view "Mint" ViewMint
      , navBtn model.view "Search" ViewAvails
      , navBtn model.view "Generator" ViewGenerator
      ]
        |> row
            [ spacing 5
            , alignLeft
            , Font.size (fork model.isMobile 13 19)
            ]
    , (case model.view of
        ViewHome ->
            none

        ViewMint ->
            viewMint model

        ViewGenerator ->
            none

        ViewAvails ->
            viewAvails model
      )
        |> el
            [ Background.color white
            , padding 20
            , width fill
            , shadow
            ]
    ]
        |> column
            [ width fill
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
                [ para [] "You will need to provide a Solana keypair file that begins with 'pow', followed by a number."
                , text "Examples:"
                , renderPow [ "pow", "8", "i1DzJkTqEuEPAViZFWheptCohFEhCwzRX7epZCj" ]
                    |> el [ Font.size 16 ]
                , renderPow [ "pow", "297", "i8QJcqU8QbdpaHYLCgnvMqVwf3c8DnEcB3ZLg" ]
                    |> el [ Font.size 16 ]
                , renderPow [ "pow", "11", "S27f9ju6QP8kBAC3XaVXYFynygkqd6zmjnbaPw" ]
                    |> el [ Font.size 16 ]
                , select
                ]
                    |> column [ spacing 20 ]
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
                    --"https://solana.fm/tx/"
                    --++ sig
                    --++ explorerSuffix
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

                            tier =
                                String.length idStr
                        in
                        nft.mint
                            |> unwrap
                                (if tier == 5 || tier == 6 then
                                    [ text ("POW #" ++ idStr)
                                        |> el [ Font.size 22, centerX, Font.bold ]
                                    , para [ Font.center ] "Minting of Tier 5 and Tier 6 NFTs has ended. Please save this Keypair, it will be used in a future proof-of-work verification."
                                    , [ text "Total Minted"
                                            |> el [ Font.bold ]
                                      , text "Tier 5: 5561"
                                      , text "Tier 6: 930"
                                      ]
                                        |> column [ spacing 10 ]
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
                                    , text "Connect a Solana wallet to continue"
                                    , model.wallet
                                        |> unwrap
                                            (text "Select wallet"
                                                |> btn (Just SelectWallet) [ padding 10, Border.width 1 ]
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
                                (\mint ->
                                    [ text ("POW #" ++ idStr ++ " has already been minted")
                                        |> el [ Font.italic ]
                                    , nftLink mint
                                    ]
                                        |> column [ spacing 10 ]
                                )
                    )
    ]
        |> column [ spacing 20 ]


viewAvails model =
    [ para [ Font.bold ] "Find your next POW NFT!"
    , [ para [ Font.italic ] "Enter an NFT ID to check if it is available"
      , [ Input.text
            [ width <| px 170
            , Html.Attributes.type_ "number"
                |> htmlAttribute
            , Html.Attributes.min "1"
                |> htmlAttribute
            , Html.Attributes.max "4294967295"
                |> htmlAttribute
            , onKeydown "Enter" SubmitId
                |> whenAttr (not model.idWaiting)
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
            |> btn
                (if model.idWaiting then
                    Nothing

                 else
                    Just SubmitId
                )
                [ padding 10
                , Border.width 1
                , Background.color white
                ]
        , spinner 30
            |> when model.idWaiting
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
    , let
        idStr =
            String.fromInt model.idInProg
      in
      model.idCheck
        |> whenJust
            (unwrap
                (if String.length idStr == 5 || String.length idStr == 6 then
                    [ para [ Font.center ] "Minting of Tier 5 and Tier 6 NFTs has ended. This NFT was not minted."
                    , [ text "Total Minted"
                            |> el [ Font.bold ]
                      , text "Tier 5: 5561"
                      , text "Tier 6: 930"
                      ]
                        |> column [ spacing 10 ]
                    ]
                        |> column [ spacing 20 ]

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
                (\addr ->
                    [ text ("NFT #" ++ idStr ++ " has already been minted")
                        |> el [ Font.size 22, centerX ]
                    , nftLink addr
                    ]
                        |> column [ spacing 10 ]
                )
            )
    ]
        --|> column [ spacing 30 ]
        |> column
            [ spacing 10
            , height fill
            , scrollbarY
            ]


viewBanner model =
    [ --[ text ("The world's first proof-of-work NFT  " ++ bang)
      --]
      --|> paragraph
      --[ Font.center
      --, centerX
      --, Font.size (fork model.isMobile 17 22)
      --]
      [ text "$"
            |> el [ Font.color gold ]
      , text "solana-keygen grind"
      ]
        |> row
            [ Font.size (fork model.isMobile 17 22)
            , blockFont
            , spacing 8
            ]
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
        --, style "animation-name" "enter"
        --, style "animation-delay" (String.fromFloat delay ++ "s")
        --, style "animation-duration" "1s"
        --, style "animation-fill-mode" "forwards"
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


comicFont =
    Font.family [ Font.typeface "Bangers" ]


titleFont =
    Font.family [ Font.typeface "Bowlby One SC" ]


blockFont =
    Font.family [ Font.typeface "IBM Plex Mono" ]


mainFont =
    --Font.family [ Font.typeface "Roboto" ]
    Font.family [ Font.typeface "Montserrat Variable" ]


btn msg attrs elem =
    Input.button
        ((if msg == Nothing then
            []

          else
            [ hover ]
         )
            ++ attrs
            ++ [--titleFont
               ]
        )
        { onPress = msg
        , label = elem
        }


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
            [ --, Border.width 2
              Background.color
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


renderPow addr =
    renderPowTrunc addr False


renderPowTrunc addr trunc =
    addr
        |> List.indexedMap
            (\n txt ->
                if n == 0 then
                    text txt
                    --|> el
                    --[ Font.italic
                    --]

                else if n == 1 then
                    text txt
                        |> el
                            [ Font.bold

                            --, Font.size 20
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

            --, Font.size 16
            ]


spinner : Int -> Element msg
spinner n =
    Img.notch n
        |> el [ spinAttr ]


nftLink mint =
    newTabLink [ hover ]
        { url =
            "https://solscan.io/token/"
                ++ mint

        --"https://solana.fm/address/"
        --++ pair.publicKey
        --++ explorerSuffix
        , label = text "View NFT"
        }


viewX =
    newTabLink
        [ Background.color white
        , shadow
        , blockFont
        , hover
        , paddingXY 20 10
        ]
        { url = "https://x.com/pow_mint"
        , label =
            [ Img.x 20
            , text "@pow_mint"
            ]
                |> row [ spacing 15 ]
        }


wrapBox =
    el
        [ Background.color white
        , padding 10
        , shadow
        ]


fadeIn =
    style "animation" "fadeIn 1s"


viewNav model =
    [ navBtn model.view "🏠" ViewHome
    , navBtn model.view "Search 🔍" ViewAvails
    , navBtn model.view "Grind 🎰" ViewGenerator

    --, navBtn model.view "Keygen 🎰" ViewGenerator
    , navBtn model.view ("Mint " ++ bang) ViewMint
    , image [ height <| px 26 ]
        { src = "/github.png"
        , description = ""
        }
        |> linkOut "https://github.com/ronanyeah/pow-dapp" [ alignRight, padding 3 ]
    ]
        |> row
            [ spacing 10
            , width fill
            , Font.size (fork model.isMobile 16 19)
            ]


bang =
    String.fromChar '💥'


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


formatKeycount n =
    if n > 1000000 then
        formatFloat (toFloat (n // 1000) / 1000) ++ "m"

    else
        String.fromInt (n // 1000) ++ "k"
