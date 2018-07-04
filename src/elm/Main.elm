-- core
import Platform.Sub exposing (batch)

-- elm-lang
import AnimationFrame exposing (diffs)
import Html exposing (Html)
import WebSocket

-- local
import Conf exposing (wsServer)
import Model exposing (Model, Point, Frustum, Display)
import Update exposing (..)
import View exposing (..)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


init : (Model, Cmd Msg)
init =
  ( Model
      []
      -1.0
      (Frustum "-1.5" "1.5" "-1.0" "1.0")
      0.0
      (Display 900 600)
      False
  , Cmd.none
  )

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  batch
  [ WebSocket.listen wsServer NewMessage
  --, AnimationFrame.diffs NewFrame
  ]
