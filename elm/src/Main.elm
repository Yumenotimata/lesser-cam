module Main exposing (..)

import Browser
import CameraHandler exposing (CameraHandler, getCameraList)
import Cmd.Extra as C
import Do.Task as T
import Html as H
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
    , cameraH : Maybe CameraHandler
    , availableCameraList : List String
    , selectedCamera : Maybe String
    }


type Msg
    = OpenCameraClick
    | CameraSelect String
    | InitCameraH CameraHandler
    | GetAvailableCameraList
    | GotAvailableCameraList CameraHandler.GetCameraListResponse
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
    ( { cameraH = Nothing
      , error = Nothing
      , availableCameraList = []
      , selectedCamera = Nothing
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
                        |> Select.setOnChange CameraSelect
                    )
                    (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
                    (model.availableCameraList
                        |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
                    )
                , IconButton.iconButton
                    (IconButton.config |> IconButton.setOnClick OpenCameraClick)
                    (IconButton.icon "launch")
                ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenCameraClick ->
            case model.selectedCamera of
                _ ->
                    ( model, Cmd.none )

        CameraSelect cameraName ->
            ( { model | selectedCamera = Just cameraName }, Cmd.none )

        InitCameraH cameraH ->
            ( { model | cameraH = Just cameraH }, C.perform GetAvailableCameraList )

        GetAvailableCameraList ->
            case model.cameraH of
                Just cameraH ->
                    let
                        task =
                            getCameraList cameraH
                                |> T.map (R.unpack (D.errorToString >> FatalException) GotAvailableCameraList)
                                |> unwrapTask
                    in
                    ( model, task )

                Nothing ->
                    ( model, C.perform <| FatalException "no camera handler" )

        GotAvailableCameraList res ->
            ( { model | availableCameraList = res.cameras }, Cmd.none )

        FatalException error ->
            ( { model | error = Just error }, Cmd.none )

        None ->
            ( model, Cmd.none )


subscriptions model =
    Sub.none


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> FatalException)
        |> T.attempt R.merge
