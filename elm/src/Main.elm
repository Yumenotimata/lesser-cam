module Main exposing (..)

import Browser
import Grpc as G
import Html
import Html.Events exposing (onClick)
import Json.Encode as E
import Proto.Camera exposing (OpenCameraRequest, OpenCameraResponse)
import Proto.Camera.CameraService as CameraService exposing (openCamera)
import Result as R
import Result.Extra as R
import Task as T



-- import TaskPort as TP


type alias Model =
    { error : Maybe String

    -- , camera : Maybe Camera
    }


type Msg
    = OpenCamera String
    | SetCamera OpenCameraResponse
    | Throw String
    | None


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init () =
    ( { error = Nothing }, Cmd.none )


view model =
    Html.div []
        [ Html.button [ onClick (OpenCamera "test_path") ] [ Html.text "Open Camera" ]
        , model.error
            |> Maybe.map Html.text
            |> Maybe.withDefault (Html.text "")
        ]


errorToString : G.Error -> String
errorToString error =
    case error of
        G.BadUrl _ ->
            "Bad URL"

        G.Timeout ->
            "Timeout"

        G.NetworkError ->
            "Network error"

        _ ->
            "Unknown error"


update msg model =
    case msg of
        OpenCamera name ->
            let
                openCameraTask =
                    G.new openCamera { name = name }
                        |> G.setHost "http://localhost:50051"
                        |> G.toTask
                        |> T.map SetCamera
                        |> T.mapError (\e -> Throw (errorToString e))
                        |> T.attempt R.merge
            in
            ( model, openCameraTask )

        SetCamera response ->
            ( { model | error = Just response.message }, Cmd.none )

        Throw error ->
            ( { model | error = Just error }, Cmd.none )

        None ->
            ( model, Cmd.none )


subscriptions model =
    Sub.none
