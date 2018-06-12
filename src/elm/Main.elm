-- core
import Color exposing (hsla)
import Platform.Sub exposing (batch)
import Result exposing (withDefault)
import String exposing (split, trim)
import Time exposing (Time)

-- elm-lang
import AnimationFrame exposing (diffs)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick, onInput)
import WebSocket

-- graphics
import Collage exposing (Form, collage, filled, move, rect, text)
import Element exposing (toHtml)
import Text exposing (fromString)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL
type alias Model =
  { points  : List Point
  , diff    : Float
  , frustum : Frustum
  , display : Display
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
      (Frustum -1.0 1.0 -1.0 1.0)
      (Display 600 400)
  , Cmd.none
  )

-- UPDATE
type Msg
  = NewMessage String
  | NewFrame Time
  | NewXMin String
  | NewXMax String
  | NewYMin String
  | NewYMax String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewMessage str ->
      ({ model | points = str |> getPoints |> (List.map (toDisplaySpace model))} , Cmd.none)

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
  [ WebSocket.listen "ws://localhost:8899/ws" NewMessage
  , AnimationFrame.diffs NewFrame
  ]


-- VIEW
view : Model -> Html Msg
view model =
    div []
    [ debug model
    , config model
    , display model
    ]

debug : Model -> Html Msg
debug model =
  div [] ["diff: " ++ (toString model.diff) ++ "ms" |> Html.text]

config : Model -> Html Msg
config model =
  div
    []
    [ "frustum: " |> Html.text
    , Html.input [placeholder "xmin", onInput NewXMin] []
    , Html.input [placeholder "xmax", onInput NewXMax] []
    , Html.input [placeholder "ymin", onInput NewYMin] []
    , Html.input [placeholder "ymax", onInput NewYMax] []
    ]

display : Model -> Html Msg
display model =
  collage
    model.display.width
    model.display.height
    (model.points |> List.map toSquare) |> toHtml


-- VIEW HELPERS
toSquare : Point -> Form
toSquare {x, y} =
  filled (hsla 0.5 0.5 0.6 0.3) (rect 10 10)
  |> move (x, y)
