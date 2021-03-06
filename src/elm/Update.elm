module Update exposing (..)

-- core
import Result exposing (withDefault)
import String exposing (split)
import Time exposing (Time)

-- elm-lang
import WebSocket

-- local
import Conf exposing (wsServer)
import Model exposing (Model, Point, Frustum)


type Msg
  = StartStream
  | PauseStream
  | NewMessage String
  | NewFrame Time
  | NewXMin String
  | NewXMax String
  | NewYMin String
  | NewYMax String
  | NewDelay String
  | Zoom Float


type FrustumField
  = XMin
  | XMax
  | YMin
  | YMax


type ZoomLevel
  = In
  | Out


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

    NewDelay strDelay ->
      let
        delay = withDefault 0.0 (strDelay |> String.toFloat)
      in
      ({model | delay = delay }, WebSocket.send wsServer ("DELAY " ++ strDelay))

    Zoom amount ->
      let
        level = if amount < 0 then In else Out
        new = frustumZoom model.frustum level
      in
      ({model | frustum = new}, Cmd.none)


-- UPDATE HELPERS

toDisplaySpace : Model -> Point -> Point
toDisplaySpace model p =
  let
    frustum = frustumFloat model.frustum

    ixmin = frustum.xmin
    ixmax = frustum.xmax
    dxmin = (toFloat -model.display.width) / 2
    dxmax = (toFloat model.display.width) / 2
    x = ((p.x - ixmin) / (ixmax - ixmin)) * (dxmax - dxmin) + dxmin

    iymin = frustum.ymin
    iymax = frustum.ymax
    dymin = (toFloat -model.display.height) / 2
    dymax = (toFloat model.display.height) / 2
    y = ((p.y - iymin) / (iymax - iymin)) * (dymax - dymin) + dymin

  in
    Point x y


-- Update a specific frustum field from a string
setFrustumField : Frustum -> FrustumField -> String -> Frustum
setFrustumField frustum field string =
  case field of
    XMin ->
      { frustum | xmin = string }
    XMax ->
      { frustum | xmax = string }
    YMin ->
      { frustum | ymin = string }
    YMax ->
      { frustum | ymax = string }


-- convert frustum values from strings to floats
frustumFloat : Frustum -> { xmax : Float, xmin : Float, ymax : Float, ymin : Float }
frustumFloat frustum =
  { xmin = withDefault 0.0 (String.toFloat frustum.xmin)
  , xmax = withDefault 0.0 (String.toFloat frustum.xmax)
  , ymin = withDefault 0.0 (String.toFloat frustum.ymin)
  , ymax = withDefault 0.0 (String.toFloat frustum.ymax)
  }


-- Update the frustum by magnifying or shrinking it
frustumZoom : Frustum -> ZoomLevel -> Frustum
frustumZoom frustum level =
  let
    frustumf = frustumFloat frustum
    deltaX = frustumf.xmax - frustumf.xmin
    deltaY = frustumf.ymax - frustumf.ymin

    factor =
      case level of
        In  -> -0.25
        Out ->  0.5

    newXmin = frustumf.xmin - factor * deltaX
    newXmax = frustumf.xmax + factor * deltaX
    newYmin = frustumf.ymin - factor * deltaY
    newYmax = frustumf.ymax + factor * deltaY

  in
    Frustum
      (newXmin |> toString)
      (newXmax |> toString)
      (newYmin |> toString)
      (newYmax |> toString)


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
