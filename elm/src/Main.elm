module Main exposing (..)

import Browser
import Browser.Events exposing (onAnimationFrame, onAnimationFrameDelta)
import CameraHandler exposing (Camera, CameraHandler, GetCameraImageResponseJson, getCameraList)
import Cmd.Extra as C
import Do.Task as T
import Html as H
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Material.IconButton as IconButton
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Typography as Typography
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import WebSocket exposing (WebSocket)



-- type alias Model =
--     { error : Maybe String
--     , reqS : Maybe RequiredState
--     , availableCameraList : List String
--     , selectedCamera : Maybe String
--     , openedCamera : Maybe Camera
--     , currentImage : List Int
--     }


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
    case model_ of
        Init ->
            H.div [] []

        Normal model ->
            H.div []
                [ H.h1 [ Typography.headline6 ] [ H.text "Hello World" ]
                , H.ul [] (List.map (H.text >> List.singleton >> H.li [ Typography.body1 ]) model.availableCameraList)
                , Select.filled
                    (Select.config
                        |> Select.setLabel (Just "Camera Source")
                        |> Select.setSelected model.selectedCamera
                        |> Select.setOnChange CameraSelect
                    )
                    (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
                    (model.availableCameraList
                        |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
                    )
                , IconButton.iconButton
                    (IconButton.config |> IconButton.setOnClick OpenCameraClick)
                    (IconButton.icon "launch")
                , model.openedCamera
                    |> Maybe.map (\camera -> H.text ("Opened Camera: " ++ String.fromInt camera.uuid))
                    |> Maybe.withDefault (H.text "No camera opened")
                , canvas model.currentImage
                ]

        FatalError error ->
            H.div [] [ H.text error ]

        UnreachableS error ->
            H.div [] [ H.text error ]



-- case model.error of
--     Just error ->
--         H.div [] [ H.text error ]
--     Nothing ->
--         H.div []
--             [ H.h1 [ Typography.headline6 ] [ H.text "Hello World" ]
--             , H.ul [] (List.map (H.text >> List.singleton >> H.li [ Typography.body1 ]) model.availableCameraList)
--             , Select.filled
--                 (Select.config
--                     |> Select.setLabel (Just "Camera Source")
--                     |> Select.setSelected model.selectedCamera
--                     |> Select.setOnChange CameraSelect
--                 )
--                 (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
--                 (model.availableCameraList
--                     |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
--                 )
--             , IconButton.iconButton
--                 (IconButton.config |> IconButton.setOnClick OpenCameraClick)
--                 (IconButton.icon "launch")
--             , model.openedCamera
--                 |> Maybe.map (\camera -> H.text ("Opened Camera: " ++ String.fromInt camera.uuid))
--                 |> Maybe.withDefault (H.text "No camera opened")
--             , canvas model.currentImage
--             ]


canvas bytes =
    H.node "elm-canvas" [ HA.property "bytes" (E.list E.int bytes), HA.attribute "text" "test" ] []



--  H.canvas [ HA.id "elm-canvas" ] []


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
                    ( Normal model, C.perform (FatalException "CameraHandler not initialized, but this should never happen") )

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
