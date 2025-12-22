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


type alias Model =
    { error : Maybe String
    , reqS : Maybe RequiredState
    , availableCameraList : List String
    , selectedCamera : Maybe String
    , openedCamera : Maybe Camera
    , currentImage : List Int
    }



-- アプリが正常に動作するために必ず必要なリソース
-- これを確保できなかった時点でfatal exception


type alias RequiredState =
    { cameraH : CameraHandler
    }


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
    | None


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
    ( { reqS = Nothing
      , error = Nothing
      , availableCameraList = []
      , selectedCamera = Nothing
      , openedCamera = Nothing
      , currentImage = []
      }
    , initCameraHandler
    )


view : Model -> H.Html Msg
view model =
    case model.error of
        Just error ->
            H.div [] [ H.text error ]

        Nothing ->
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


canvas bytes =
    H.node "elm-canvas" [ HA.property "bytes" (E.list E.int bytes), HA.attribute "text" "test" ] []



--  H.canvas [ HA.id "elm-canvas" ] []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.reqS of
        Nothing ->
            case msg of
                InitCameraH initCameraH ->
                    ( { model | reqS = Just { cameraH = initCameraH } }, C.perform GetAvailableCameraList )

                _ ->
                    ( model, C.perform (FatalException "unreachable!") )

        Just { cameraH } ->
            case msg of
                OpenCameraClick ->
                    case model.selectedCamera of
                        Just cameraName ->
                            let
                                task =
                                    CameraHandler.open cameraH cameraName
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCamera)
                                        |> unwrapTask
                            in
                            ( model, task )

                        _ ->
                            ( model, Cmd.none )

                CameraSelect cameraName ->
                    ( { model | selectedCamera = Just cameraName }, Cmd.none )

                GotCamera camera ->
                    ( { model | openedCamera = Just camera }, C.perform GetCameraImage )

                GetCameraImage ->
                    case model.openedCamera of
                        Just openedCamera ->
                            let
                                task =
                                    CameraHandler.getCameraImage cameraH openedCamera
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCameraImage)
                                        |> unwrapTask
                            in
                            ( model, task )

                        Nothing ->
                            ( model, C.perform (FatalException "Camera not opened") )

                GotCameraImage res ->
                    ( { model | currentImage = res.image }, C.perform GetCameraImage )

                InitCameraH _ ->
                    ( model, C.perform (FatalException "CameraHandler not initialized, but this should never happen") )

                GetAvailableCameraList ->
                    let
                        task =
                            getCameraList cameraH
                                |> T.map (R.unpack (D.errorToString >> FatalException) GotAvailableCameraList)
                                |> unwrapTask
                    in
                    ( model, task )

                GotAvailableCameraList res ->
                    ( { model | availableCameraList = res.cameras }, Cmd.none )

                FatalException error ->
                    ( { model | error = Just error }, Cmd.none )

                None ->
                    ( model, Cmd.none )


subscriptions model =
    Sub.none



-- onAnimationFrame (\_ -> GetCameraImage)
-- Sub.none
-- onAnimationFrameDelta (\_ -> GetCameraImage)


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> FatalException)
        |> T.attempt R.merge
