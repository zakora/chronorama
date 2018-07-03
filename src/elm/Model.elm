module Model exposing (Model, Point, Frustum, Display)

type alias Model =
  { points      : List Point
  , diff        : Float
  , frustum     : Frustum
  , delay       : Float
  , display     : Display
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
