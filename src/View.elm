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
import Helpers.View exposing (cappedHeight, cappedWidth, style, when, whenAttr, whenJust)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Img
import Json.Decode as JD
import Json.Encode as JE
import Maybe.Extra exposing (unwrap)
import Types exposing (..)
import Url


view : Model -> Html Msg
view model =
    (if model.screen.width >= 1024 then
        viewWide model
        --viewPalette

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
            , Background.color white

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
      --, viewGenerator model
      --|> el [ width fill, height fill ]
      , viewBanner model
            |> el
                [ width fill
                , alignBottom
                ]
      ]
        |> column
            [ height fill
            , spacing 20
            , width fill
            , fadeIn
            ]
    , [ viewNav model
      , case model.view of
            ViewHome ->
                viewInfo model

            _ ->
                viewGenerator model

      --, viewGenerator model
      --, viewPanel model
      --|> el [ centerX, width fill ]
      ]
        |> column
            [ height fill
            , width fill
            , fadeIn
            ]
    ]
        |> row
            [ width <| px 1024
            , spaceEvenly
            , centerX
            , height fill
            , cappedHeight 800
            , padding 30
            , spacing 30
            ]


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

            _ ->
                viewGenerator model
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


viewGenerator model =
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
    [ [ para [ titleFont, Font.size (fork model.isMobile 17 20) ] "Vanity Keypair Generator"
      , text "Learn more"
            |> linkOut "https://www.quicknode.com/guides/solana-development/getting-started/how-to-create-a-custom-vanity-wallet-address-using-solana-cli"
                [ Font.underline
                , Font.size 16
                , alignBottom
                , Font.italic
                ]
      ]
        |> row [ width fill ]
    , [ Input.radioRow
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
        , [ if model.grinding then
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
                    |> column [ spacing 10 ]

            else
                text "START"
                    |> btn (Just VanityGen)
                        [ titleFont
                        , Border.width 1
                        , paddingXY 15 10
                        , Background.color green
                        , Border.rounded 5
                        , Font.size (fork model.isMobile 17 19)
                        ]
          ]
            |> column [ alignRight ]
        ]
            |> row [ width fill ]
      ]
        |> column
            [ width fill
                |> whenAttr model.isMobile
            ]
    , model.message
        |> whenJust
            (\txt ->
                text
                    ("⚠️  " ++ txt)
            )
    , model.vanity
        |> List.map
            (\key ->
                [ text key.pubkey
                    |> el [ Font.size (fork model.isMobile 11 13) ]
                , downloadAs
                    [ hover
                    , padding 5
                    , alignRight
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
                    |> column
                        [ spacing 10
                        , Border.width 1
                        , width fill
                        , padding 10
                        , Background.color green
                        , Border.rounded 5
                        , fadeIn
                        ]
            )
        |> column
            [ spacing 5
            , height fill
            , scrollbarY

            --, Background.color green
            , width fill
            , spinner 30
                |> el [ centerX, padding 10 ]
                |> inFront
                |> whenAttr (List.isEmpty model.vanity && model.grinding)
            ]
    , [ [ text "Results:"
            |> el [ Font.bold ]
        , text (String.fromInt (List.length model.vanity))
        ]
            |> row [ spacing 10 ]
      , [ text "Keys checked:"
            |> el [ Font.bold ]
        , text (String.fromInt (model.count // 1000) ++ "k")
        ]
            |> row [ spacing 10 ]
      , [ text "KPS:"
            |> el [ Font.bold ]
        , text
            ((kps model.count model.startTime model.now
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
            [ Background.color white
            , paddingXY (fork model.isMobile 15 20) 20
            , cappedWidth 650
            , shadow
            , spacing 10
            , height fill
            , scrollbarY
            ]


viewInfo model =
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
    , "MINTING FEBRUARY 8th, 1PM EST"
        |> para [ comicFont, Font.center, Font.size 28 ]

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
          , text " that contains the ID in a specfific format. Exact details will be provided before the mint goes live."
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
            [ Background.color white
            , paddingXY (fork model.isMobile 15 30) 20

            --, cappedWidth 650
            , shadow
            , spacing 30
            , height fill
            , scrollbarY
            ]


viewPanel model =
    [ [ navBtn model.view "Mint" ViewMint
      , navBtn model.view "Search" ViewAvails
      , navBtn model.view "Generator" ViewGenerator
      , navBtn model.view
            --"How does this work?"
            "FAQ"
            --"Learn More"
            ViewFaq
      ]
        |> row
            [ spacing 5
            , alignLeft
            , Font.size (fork model.isMobile 13 19)
            ]
    , (case model.view of
        ViewFaq ->
            --viewInfo model
            text "???"
                |> el [ centerX ]

        ViewHome ->
            none

        ViewMint ->
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
            [ model.nftId
                |> unwrap
                    (if model.walletInUse then
                        [ text "Keypair loading"
                        , spinner 30
                            |> el [ centerX ]
                        ]
                            |> column [ spacing 20 ]

                     else
                        [ para [] "You will need to provide a Solana keypair file"
                        , select
                        ]
                            |> column [ spacing 20 ]
                    )
                    (\key ->
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
                          , [ renderPow key.parts
                            ]
                                |> row
                                    [ spacing 10
                                    , paddingXY 15 10
                                    ]
                          ]
                            |> column
                                [ spacing 0
                                , Border.width 1
                                , Border.rounded 7
                                , Background.color white
                                ]
                        , key.nft
                            |> unwrap
                                ([ text "Not a valid POW NFT keypair."

                                 --, [ text "The public key needs to gg, followed by a number." ]
                                 --|> paragraph []
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

                                        existsM =
                                            Dict.get nft.id model.availability
                                    in
                                    existsM
                                        |> unwrap (spinner 30 |> el [ centerX ])
                                            (\exists ->
                                                if exists then
                                                    [ text ("NFT #" ++ idStr ++ " has already been claimed")
                                                        |> el [ Font.italic ]
                                                    , nftLink key.pubkey
                                                    ]
                                                        |> column [ spacing 10 ]

                                                else
                                                    model.mintSig
                                                        |> unwrap
                                                            ([ text ("NFT #" ++ idStr ++ " is available!")
                                                                |> el [ Font.size 22, centerX ]

                                                             --[ text "ID: #"
                                                             --, String.fromInt id
                                                             --|> text
                                                             --|> el [ Font.bold ]
                                                             --]
                                                             --|> row []
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
                                                            (\sig ->
                                                                [ text "Success!"
                                                                    |> el [ centerX ]
                                                                , newTabLink [ hover, Font.underline ]
                                                                    { url =
                                                                        "https://solana.fm/tx/"
                                                                            ++ sig
                                                                            ++ explorerSuffix
                                                                    , label = text "View transaction"
                                                                    }
                                                                ]
                                                                    |> column [ spacing 20, centerX ]
                                                            )
                                            )
                                )
                        ]
                            |> column [ spacing 20 ]
                    )
            , model.status
                |> whenJust
                    (\status ->
                        case status of
                            0 ->
                                none

                            1 ->
                                text "Error: Not a valid POW id"

                            2 ->
                                text "Error: Not a valid keypair file."

                            _ ->
                                none
                    )
            ]
                |> column
                    [ spacing 30
                    ]

        ViewGenerator ->
            [ if model.grinding then
                text "Stop grind"
                    |> btn (Just StopGrind) [ titleFont ]

              else
                text "Grind"
                    |> btn (Just Generate) [ titleFont ]
            , text ("Checked: " ++ String.fromInt model.count)
                |> el []
            , text ("Keys: " ++ String.fromInt (List.length model.keys))
                |> el []
            , model.keys
                |> List.map
                    (\key ->
                        let
                            exists =
                                key.nft
                                    |> Maybe.andThen
                                        (\nft ->
                                            Dict.get nft.id model.availability
                                        )
                        in
                        [ key.parts
                            |> renderPow
                            |> el [ mainFont ]

                        --|> btn
                        --(if
                        --exists
                        --|> Maybe.withDefault False
                        --then
                        --Nothing
                        --else
                        --Just (UseKey key)
                        --)
                        --[]
                        , [ exists
                                |> unwrap (text "?")
                                    (\bl ->
                                        if bl then
                                            "❌ taken"
                                                |> text

                                        else
                                            "✅ mint now"
                                                |> text
                                                |> btn
                                                    (Just (UseKey key))
                                                    []
                                    )
                          , downloadAs
                                [ hover
                                , padding 10
                                ]
                                { label = text "💾"
                                , filename = key.pubkey ++ ".json"
                                , url =
                                    key.bytes
                                        |> JE.list JE.int
                                        |> JE.encode 0
                                        |> Url.percentEncode
                                        |> (++) "data:text/json;charset=utf-8,"
                                }
                          ]
                            |> row [ spaceEvenly, width fill ]
                        ]
                            |> column
                                [ spacing 10
                                , Border.width 1
                                , width fill
                                , padding 5
                                ]
                    )
                |> column [ spacing 5, height fill, scrollbarY ]
            ]
                |> column
                    [ centerX
                    , spacing 20
                    , height <| px 400
                    , width fill
                    ]

        ViewAvails ->
            [ [ [ para [] "Enter a number to check if the NFT exists"
                , para [] "Note: Id's cannot contain any '0' characters."
                ]
                    |> column [ spacing 5 ]
              , [ Input.text
                    [ width <| px 150
                    , Html.Attributes.type_ "number"
                        |> htmlAttribute
                    , Html.Attributes.maxlength 5
                        |> htmlAttribute
                    ]
                    { label =
                        --|> Input.labelAbove []
                        Input.labelHidden ""
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
                        ]
                , spinner 30
                    |> when model.idWaiting
                ]
                    |> row [ spacing 20 ]
              ]
                |> column [ spacing 20 ]
            , let
                idStr =
                    String.fromInt model.idInProg
              in
              model.idCheck
                |> whenJust
                    (unwrap
                        ([ text ("NFT #" ++ idStr ++ " is available!")
                            |> el [ Font.size 22, centerX ]
                         , text "Get it by using:"

                         --, "solana-keygen grind --gg ---"
                         --++ idStr
                         --++ ":1"
                         --|> text
                         --|> el
                         --[ paddingXY 30 15
                         --, Background.color beige
                         --]
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
                         , newTabLink [ Font.underline, hover ]
                            { url = "https://docs.solana.com/cli/install-solana-cli-tools"
                            , label = text "Install the necessary tools here"
                            }
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
                |> column [ spacing 30 ]
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
                            , Font.size 22
                            ]

                else
                    text txt
            )
        |> row [ spacing 1, Font.size 17 ]


spinner : Int -> Element msg
spinner n =
    Img.notch n
        |> el [ spinAttr ]


nftLink mint =
    newTabLink [ hover ]
        { url =
            "https://solscan.io/token/"
                ++ mint
                ++ "?cluster=devnet"

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
    [ navBtn model.view ("Mint " ++ bang) ViewHome
    , navBtn model.view "Vanity Generator" ViewGenerator
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


explorerSuffix =
    "?cluster=devnet-solana"


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


formatFloat n =
    FormatNumber.format
        { usLocale
            | decimals = FormatNumber.Locales.Exact 2
        }
        (n / 1000)
