-- core
import Color exposing (rgba, rgb)
import Platform.Sub exposing (batch)
import Result exposing (withDefault)
import String exposing (split, trim)
import Time exposing (Time)

-- elm-lang
import AnimationFrame exposing (diffs)
import Html exposing (Html, div)
import Html.Attributes exposing (id, placeholder, value)
import Html.Events exposing (onClick, onInput)
import WebSocket

-- graphics
import Collage exposing (Form, collage, filled, move, rect, text)
import Element exposing (toHtml)
import Text exposing (fromString)


wsServer = "ws://localhost:8899/ws"


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL
type alias Model =
  { points    : List Point
  , diff      : Float
  , frustum   : Frustum
  , display   : Display
  , isStreaming : Bool
  }

type alias Point =
  { x : Float
  , y : Float
  }

type alias Frustum =
  { xmin : Float
  , xmax : Float
  , ymin : Float
  , ymax : Float
  }

type alias Display =
  { width  : Int
  , height : Int
  }

init : (Model, Cmd Msg)
init =
  ( Model
      []
      -1.0
      (Frustum -1.5 1.5 -1.0 1.0)
      (Display 900 600)
      False
  , Cmd.none
  )

-- UPDATE
type Msg
  = StartStream
  | PauseStream
  | NewMessage String
  | NewFrame Time
  | NewXMin String
  | NewXMax String
  | NewYMin String
  | NewYMax String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    StartStream ->
      ({model | isStreaming = True}, WebSocket.send wsServer "READY")

    PauseStream ->
      ({model | isStreaming = False}, WebSocket.send wsServer "PAUSE")

    NewMessage str ->
      ({ model | points = str |> getPoints} , Cmd.none)

    NewFrame time ->
      ({ model | diff = time}, Cmd.none)

    NewXMin newXMin ->
      let
        new = setFrustumField model.frustum XMin newXMin
      in
        ({ model | frustum = new}, Cmd.none)

    NewXMax newXMax ->
      let
        new = setFrustumField model.frustum XMax newXMax
      in
        ({ model | frustum = new}, Cmd.none)

    NewYMin newYMin ->
      let
        new = setFrustumField model.frustum YMin newYMin
      in
        ({ model | frustum = new}, Cmd.none)

    NewYMax newYMax ->
      let
        new = setFrustumField model.frustum YMax newYMax
      in
        ({ model | frustum = new}, Cmd.none)


-- UPDATE HELPERS

toDisplaySpace : Model -> Point -> Point
toDisplaySpace model p =
  let
    ixmin = model.frustum.xmin
    ixmax = model.frustum.xmax
    dxmin = (toFloat -model.display.width) / 2
    dxmax = (toFloat model.display.width) / 2
    x = ((p.x - ixmin) / (ixmax - ixmin)) * (dxmax - dxmin) + dxmin

    iymin = model.frustum.ymin
    iymax = model.frustum.ymax
    dymin = (toFloat -model.display.height) / 2
    dymax = (toFloat model.display.height) / 2
    y = ((p.y - iymin) / (iymax - iymin)) * (dymax - dymin) + dymin

  in
    Point x y


type FrustumField
  = XMin
  | XMax
  | YMin
  | YMax

-- Update a specific frustum field from a string
setFrustumField : Frustum -> FrustumField -> String -> Frustum
setFrustumField frustum field string =
  let
    result = string |> String.toFloat
  in
  case field of
    XMin ->
      { frustum | xmin = withDefault frustum.xmin result }
    XMax ->
      { frustum | xmax = withDefault frustum.xmax result }
    YMin ->
      { frustum | ymin = withDefault frustum.ymin result }
    YMax ->
      { frustum | ymax = withDefault frustum.ymax result }

-- Parse strings to make 2D points
getPoints : String -> List Point
getPoints str = str
  |> split " "
  |> pairs
  |> points

-- Group values by 2 to make pairs
pairs : List String -> List (String, String)
pairs values =
  recPairs values []

recPairs : List String -> List (String, String) -> List (String, String)
recPairs values acc =
  case values of
    [] ->
      acc
    all ->
      let
        first = all |> List.head
        second = all |> List.drop 1 |> List.head
        pair =
          case (first, second) of
            (Nothing, _) ->
              []
            (_, Nothing) ->
              []
            (Just a, Just b) ->
              [(a, b)]
        new_values = List.drop 2 all
      in
        recPairs new_values (pair ++ acc)

-- Convert string pairs to a list of points
points : List (String, String) -> List Point
points values =
  recPoints values []

recPoints : List (String, String) -> List Point -> List Point
recPoints values acc =
  case values of
    [] ->
      acc
    (a, b) :: rest ->
      let
          x = a |> String.toFloat
          y = b |> String.toFloat
          pair =
            case (x, y) of
              (Err _, _) ->
                []
              (_, Err _) ->
                []
              (Ok val1, Ok val2) ->
                [Point val1 val2]
      in
         recPoints rest (pair ++ acc)

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  batch
  [ WebSocket.listen wsServer NewMessage
  --, AnimationFrame.diffs NewFrame
  ]


-- VIEW
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
    streamAction = if model.isStreaming then "pause" else "play"
    msg = if model.isStreaming then PauseStream else StartStream

  in

  div
    [ id "actions" ]
    [ Html.section
        []
        [ Html.h2 [] [ "Actions" |> Html.text ]
        , Html.button
            [ onClick msg ]
            [ streamAction |> Html.text ]
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
        , Html.fieldset
            []
            [ Html.legend [] [ "frustum" |> Html.text ]
            , Html.label
                []
                [ "xmin" |> Html.text
                , Html.input
                    [ placeholder "xmin"
                    , onInput NewXMin
                    ]
                    []
                ]
            , Html.label
                []
                [ "xmax" |> Html.text
                , Html.input
                    [ placeholder "xmax"
                    , onInput NewXMax
                    ]
                    []
                ]
            , Html.label
                []
                [ "ymin" |> Html.text
                , Html.input
                    [ placeholder "ymin"
                    , onInput NewYMin
                    ]
                    []
                ]
            , Html.label
                []
                [ "ymax" |> Html.text
                , Html.input
                    [ placeholder "ymax"
                    , onInput NewYMax
                    ]
                    []
                ]
            ]
        ]
    ]


display : Model -> Html Msg
display model =
  div
    [ id "canvas" ]
    [ collage
        model.display.width
        model.display.height
        (model.points |> List.map (toDisplaySpace model) |> List.map toSquare) |> toHtml
    ]


-- VIEW HELPERS
toSquare : Point -> Form
toSquare {x, y} =
  filled (rgba 250 250 250 0.7) (rect 7 7)
  |> move (x, y)
