module Main exposing (..)

import Browser
import CameraHandler exposing (CameraHandler, getCameraList)
import Cmd.Extra as C
import Do.Task as T
import Html
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import WebSocket exposing (WebSocket)


type alias Model =
    { error : Maybe String
    , cameraH : Maybe CameraHandler
    , availableCameraList : List String
    }


type Msg
    = InitCameraH CameraHandler
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
    ( { cameraH = Nothing, error = Nothing, availableCameraList = [] }, initCameraHandler )


view : Model -> Html.Html Msg
view model =
    Html.div []
        [ model.cameraH
            |> Maybe.map
                (\camH -> Html.text "has camera")
            |> Maybe.withDefault (Html.text "no camera")
        , model.availableCameraList
            |> List.map Html.text
            |> Html.ul []
        , model.error
            |> Maybe.map Html.text
            |> Maybe.withDefault (Html.text "")
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
