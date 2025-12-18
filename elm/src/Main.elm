module Main exposing (..)

import Browser
import Grpc as G
import GrpcHandler as GH
import Html
import Html.Events exposing (onClick)
import Json.Encode as E
import Proto.Camera exposing (OpenCameraRequest, OpenCameraResponse)
import Proto.Camera.CameraService as CameraService exposing (openCamera)
import Result as R
import Result.Extra as R
import Task as T


type alias Model =
    { error : Maybe String
    , grpcHandler : GH.GrpcHandler
    }


type Msg
    = OpenCamera String
    | SetCamera OpenCameraResponse
    | Throw String
    | None


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init () =
    ( { grpcHandler = GH.new "http://localhost:50051", error = Nothing }, Cmd.none )


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
                    GH.send model.grpcHandler CameraService.openCamera { name = name }
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
