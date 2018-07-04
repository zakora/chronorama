module View exposing (..)

-- core
import Color exposing (rgba, rgb)
import Json.Decode as Json

-- elm-lang
import Html exposing (Html, Attribute, div)
import Html.Attributes exposing (disabled, id, placeholder, value)
import Html.Events exposing (on, onClick, onInput, onSubmit)

-- graphics
import Collage exposing (Form, collage, filled, move, rect, text)
import Element exposing (toHtml)

-- local
import Model exposing (Model, Point)
import Update exposing (..)


view : Model -> Html Msg
view model =
    div
      [ id "app" ]
      [ div
          [ id "center" ]
          [ display model ]
      , div
          [ id "menu" ]
          [ title
          , actions model
          , config model
          ]
      ]

debug : Model -> Html Msg
debug model =
  div [] ["diff: " ++ (toString model.diff) ++ "ms" |> Html.text]

title : Html Msg
title =
  Html.h1
    [ id "title" ]
    [ "Chronorama" |> Html.text ]

actions : Model -> Html Msg
actions model =
  let
    boolDisabled = if model.isStreaming then True else False

  in

  div
    [ id "actions" ]
    [ Html.section
        []
        [ Html.h2 [] [ "Actions" |> Html.text ]
        , Html.button
            [ onClick StartStream
            , disabled boolDisabled
            ]
            [ "start" |> Html.text ]
        ]
    ]



config : Model -> Html Msg
config model =
  div
    [ id "config" ]
    [ Html.section
        []
        [ Html.h2
            []
            [ "Configuration" |> Html.text ]
        , Html.form
            []
            [ Html.fieldset
                []
                [ Html.legend [] [ "frustum" |> Html.text ]
                , label "xmin" model.frustum.xmin NewXMin
                , label "xmax" model.frustum.xmax NewXMax
                , label "ymin" model.frustum.ymin NewYMin
                , label "ymax" model.frustum.ymax NewYMax
                ]
            -- TODO check how to implement minimum delay setting
            -- , label "delay" NewDelay
            ]
        ]
    ]


display : Model -> Html Msg
display model =
  div
    [ id "canvas"
    , onWheel Zoom
    ]
    [ collage
        model.display.width
        model.display.height
        (model.points |> List.map (toDisplaySpace model) |> List.map toSquare) |> toHtml
    ]


-- VIEW HELPERS

label : String -> String -> (String -> Msg) -> Html Msg
label title val msg =
  Html.label
    []
    [ title |> Html.text
    , Html.input
        [ placeholder title
        , value val
        , onInput msg
        ]
        []
    ]


toSquare : Point -> Form
toSquare {x, y} =
  filled (rgba 250 250 250 0.7) (rect 7 7)
  |> move (x, y)


onWheel : (Float -> msg) -> Attribute msg
onWheel message =
  on "wheel" (Json.map message (Json.at [ "deltaY" ] Json.float))
