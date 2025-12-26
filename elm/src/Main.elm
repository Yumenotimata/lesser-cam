module Main exposing (..)

-- import Css exposing (..)
-- import Html.Styled
-- import Material.Icons as MaterialIcons
-- import Html.Grid as Grid

import Browser
import Browser.Dom exposing (Element)
import Browser.Events exposing (onAnimationFrame, onAnimationFrameDelta)
import Cmd.Extra as C
import Css exposing (..)
import Do.Task as T
import Element
import Element.Input as Input
import Framework.Grid as LayoutGrid
import Framework.Input as Input
import Framework.Slider as Slider
import Html as H
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Html.Styled as HS exposing (toUnstyled)
import Html.Styled.Attributes as HS
import Json.Decode as D
import Json.Encode as E
import Material.Button as Button
import Material.IconButton as IconButton exposing (Icon, icon)
import Material.Icons.Action
import Material.LayoutGrid as LayoutGrid
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Typography as Typography
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import Widget
import Widget.Icon as Icon exposing (Icon)
import Widget.Material as Material


type Model
    = Init
    | Normal
        { availableCameraList : List String
        , selectedCamera : Maybe String
        , currentImage : List Int
        , virtualCameraName : Maybe String
        , virtualCameraResolution : Int
        }
    | FatalError String
    | UnreachableS String


type Msg
    = OpenCameraClick
    | CameraSelect String
    | SetVirtualCameraName String
    | SetVirtualCameraResolution Int
    | Publish
    | FatalException String
    | Unreachable String


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Init, Cmd.none )


view : Model -> H.Html Msg
view model_ =
    case model_ of
        Init ->
            H.div [] []

        _ ->
            H.div [] []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model_ =
    case model_ of
        Init ->
            case msg of
                _ ->
                    ( Init, C.perform (Unreachable "failed to initialize camera handler") )

        _ ->
            ( model_, Cmd.none )


subscriptions model =
    Sub.none


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> FatalException)
        |> T.attempt R.merge
