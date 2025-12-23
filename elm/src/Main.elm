module Main exposing (..)

-- import Css exposing (..)
-- import Html.Styled
-- import Material.Icons as MaterialIcons

import Browser
import Browser.Dom exposing (Element)
import Browser.Events exposing (onAnimationFrame, onAnimationFrameDelta)
import CameraHandler exposing (Camera, CameraHandler, GetCameraImageResponseJson, getCameraList)
import Cmd.Extra as C
import Css exposing (..)
import Do.Task as T
import Element
import Html as H
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Html.Grid as Grid
import Html.Styled as HS exposing (toUnstyled)
import Html.Styled.Attributes as HS
import Json.Decode as D
import Json.Encode as E
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
import WebSocket exposing (WebSocket)
import Widget as W
import Widget.Icon as Icon exposing (Icon)
import Widget.Material as W


type Model
    = Init
    | Normal { cameraH : CameraHandler, availableCameraList : List String, selectedCamera : Maybe String, openedCamera : Maybe Camera, currentImage : List Int }
    | FatalError String
    | UnreachableS String


type Msg
    = OpenCameraClick
    | CameraSelect String
    | InitCameraH CameraHandler
    | GetCameraImage
    | GotCameraImage GetCameraImageResponseJson
    | GetAvailableCameraList
    | GotAvailableCameraList CameraHandler.GetCameraListResponse
    | GotCamera Camera
    | FatalException String
    | Unreachable String


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initCameraHandler =
            CameraHandler.new ()
                |> T.map InitCameraH
                |> unwrapTask
    in
    ( Init
    , initCameraHandler
    )


view : Model -> H.Html Msg
view model_ =
    Element.layout [ Element.padding 0 ]
        (W.button
            (W.containedButton W.defaultPalette)
            { text = "Open Camera"
            , onPress = Just OpenCameraClick
            , icon =
                Material.Icons.Action.done
                    |> Icon.materialIcons
            }
        )



-- view : Model -> H.Html Msg
-- view model_ =
--     case model_ of
--         Init ->
--             H.div [] [ W.button (W.containedButton W.defaultPalette) { text = "Open Camera", onPress = Nothing, icon = Just "launch" } ]
--         Normal model ->
--             H.div [ HA.style "width" "100%", HA.style "height" "100vh", HA.style "display" "block", HA.style "overflow" "hidden" ]
--                 [ Select.filled
--                     (Select.config
--                         |> Select.setLabel (Just "Camera Source")
--                         |> Select.setSelected model.selectedCamera
--                         |> Select.setOnChange CameraSelect
--                     )
--                     (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
--                     (model.availableCameraList
--                         |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
--                     )
--                 , IconButton.iconButton
--                     (IconButton.config |> IconButton.setOnClick OpenCameraClick)
--                     (IconButton.icon "launch")
--                 , Grid.box
--                     [ width (pct 100), height (pct 100) ]
--                     [ Grid.row
--                         [ width (pct 100), height (pct 100) ]
--                         [ Grid.col
--                             [ Grid.exactWidthCol (pct 70), height (pct 100) ]
--                             [ canvas model.currentImage ]
--                         , Grid.col
--                             []
--                             [ HS.text "2" ]
--                         ]
--                     ]
--                     |> toUnstyled
--                 ]
--         FatalError error ->
--             H.div [] [ H.text error ]
--         UnreachableS error ->
--             H.div [] [ H.text error ]


canvas bytes =
    HS.node "elm-canvas"
        [ HS.property "bytes" (E.list E.int bytes)

        -- , HS.attribute "width" "100%"
        -- , HS.attribute "height" "100%"
        , HS.attribute "style" "width: 100%; height: 100%; display: block;"
        ]
        [ HS.div [ HS.attribute "style" "width: 100%; height: 100%; display: block;" ]
            [ HS.canvas [ HS.id "canvas" ] []
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model_ =
    case model_ of
        Init ->
            case msg of
                InitCameraH initCameraH ->
                    ( Normal
                        { cameraH = initCameraH
                        , availableCameraList = []
                        , selectedCamera = Nothing
                        , openedCamera = Nothing
                        , currentImage = []
                        }
                    , C.perform GetAvailableCameraList
                    )

                _ ->
                    ( Init, C.perform (Unreachable "failed to initialize camera handler") )

        Normal model ->
            case msg of
                OpenCameraClick ->
                    case model.selectedCamera of
                        Just cameraName ->
                            let
                                task =
                                    CameraHandler.open model.cameraH cameraName
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCamera)
                                        |> unwrapTask
                            in
                            ( model_, task )

                        _ ->
                            ( model_, C.perform (Unreachable "failed to open camera") )

                CameraSelect cameraName ->
                    ( Normal { model | selectedCamera = Just cameraName }, Cmd.none )

                GotCamera camera ->
                    ( Normal { model | openedCamera = Just camera }, C.perform GetCameraImage )

                GetCameraImage ->
                    case model.openedCamera of
                        Just openedCameraJ ->
                            let
                                task =
                                    CameraHandler.getCameraImage model.cameraH openedCameraJ
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCameraImage)
                                        |> unwrapTask
                            in
                            ( model_, task )

                        Nothing ->
                            ( model_, C.perform (FatalException "Camera not opened") )

                GotCameraImage res ->
                    ( Normal { model | currentImage = res.image }, C.perform GetCameraImage )

                InitCameraH _ ->
                    ( Normal model, C.perform (Unreachable "camera handler is already initialized") )

                GetAvailableCameraList ->
                    let
                        task =
                            getCameraList model.cameraH
                                |> T.map (R.unpack (D.errorToString >> FatalException) GotAvailableCameraList)
                                |> unwrapTask
                    in
                    ( Normal model, task )

                GotAvailableCameraList res ->
                    ( Normal { model | availableCameraList = res.cameras }, Cmd.none )

                FatalException error ->
                    ( FatalError error, Cmd.none )

                Unreachable error ->
                    ( UnreachableS error, Cmd.none )

        _ ->
            ( model_, Cmd.none )


subscriptions model =
    Sub.none


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> FatalException)
        |> T.attempt R.merge
