module Main exposing (..)

import Browser
import Html
import Html.Events exposing (onClick)
import Json.Encode as E
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import WebSocket exposing (WebSocket)


type alias Model =
    { ws : Maybe WebSocket
    , error : Maybe String
    }


type Msg
    = OpenWebSocket String
    | SetWebSocket WebSocket
    | SendWebSocket WebSocket String
    | Throw String
    | None


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init () =
    ( { ws = Nothing, error = Nothing }, Cmd.none )


view model =
    Html.div []
        [ Html.button [ onClick (OpenWebSocket "ws://localhost:8000/ws") ] [ Html.text "Open WebSocket" ]
        , model.ws
            |> Maybe.map (\ws -> Html.button [ onClick (SendWebSocket ws "Hello") ] [ Html.text "Send WebSocket" ])
            |> Maybe.withDefault (Html.text "WebSocket is not open")
        , model.error
            |> Maybe.map Html.text
            |> Maybe.withDefault (Html.text "")
        ]


update msg model =
    case msg of
        OpenWebSocket url ->
            let
                openWebSocketTask =
                    WebSocket.open url
                        |> T.map SetWebSocket
                        |> T.mapError (TP.errorToString >> Throw)
                        |> T.attempt R.merge
            in
            ( model, openWebSocketTask )

        SetWebSocket ws ->
            ( { model | ws = Just ws }, Cmd.none )

        SendWebSocket ws message ->
            let
                sendWebSocketTask =
                    WebSocket.sendWebSocket ws (E.object [ ( "OpenCamera", E.object [ ( "path", E.string "test_path" ) ] ) ])
                        |> T.map (\_ -> None)
                        |> T.mapError (TP.errorToString >> Throw)
                        |> T.attempt R.merge
            in
            ( model, sendWebSocketTask )

        Throw error ->
            ( { model | error = Just error }, Cmd.none )

        None ->
            ( model, Cmd.none )


subscriptions model =
    Sub.none
