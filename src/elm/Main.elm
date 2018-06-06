-- core
import Color exposing (hsla)
import Platform.Sub exposing (batch)
import String exposing (split, trim)
import Time exposing (Time)

-- elm-lang
import AnimationFrame exposing (diffs)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
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
  { points : List Point
  , diff : Float
  }

type alias Point =
  { x : Float
  , y : Float
  }

init : (Model, Cmd Msg)
init =
  (Model [] -1.0, Cmd.none)

-- UPDATE
type Msg
  = NewMessage String
  | NewFrame Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewMessage str ->
      ({ model | points = str |> getPoints} , Cmd.none)
    NewFrame time ->
      ({ model | diff = time}, Cmd.none)

getPoints : String -> List Point
getPoints str = str
  |> split " "
  |> pairs
  |> points

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
    [ "diff: " ++ (toString model.diff) ++ "ms" |> Html.text
    , collage 600 400
      (model.points |> List.map toSquare)
      |> toHtml
    ]

toSquare : Point -> Form
toSquare {x, y} =
  filled (hsla 0.5 0.5 0.6 0.3) (rect 10 10)
  |> move (x, y)
