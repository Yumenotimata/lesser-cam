module Main exposing (..)

import Browser
import Camera exposing (Camera)
import Html
import Html.Events exposing (onClick)
import Json.Encode as E
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import WebSocket exposing (WebSocket)


type alias Model =
    { error : Maybe String
    , camera : Maybe Camera
    }


type Msg
    = OpenCamera String
    | SetCamera Camera
    | Throw String
    | None


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init () =
    ( { camera = Nothing, error = Nothing }, Cmd.none )


view model =
    Html.div []
        [ Html.button [ onClick (OpenCamera "test_path") ] [ Html.text "Open Camera" ]
        , model.error
            |> Maybe.map Html.text
            |> Maybe.withDefault (Html.text "")
        ]


update msg model =
    case msg of
        OpenCamera name ->
            let
                openCameraTask =
                    Camera.open name
                        |> T.map SetCamera
                        |> T.mapError (TP.errorToString >> Throw)
                        |> T.attempt R.merge
            in
            ( model, openCameraTask )

        SetCamera camera ->
            ( { model | camera = Just camera }, Cmd.none )

        Throw error ->
            ( { model | error = Just error }, Cmd.none )

        None ->
            ( model, Cmd.none )


subscriptions model =
    Sub.none
