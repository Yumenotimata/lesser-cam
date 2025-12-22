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
    , selectableCameras : List String
    }


type Msg
    = SetCameraH CameraHandler
    | GetCameraH (CameraHandler -> Cmd Msg)
    | SetSelectableCameras (List String)
    | Throw String
    | None


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initCameraHandler =
            CameraHandler.new ()
                |> T.map SetCameraH
    in
    let
        getCameraListTask =
            initCameraHandler
                |> T.andThen
                    (\_ ->
                        T.succeed <|
                            GetCameraH
                                (\camH ->
                                    getCameraList camH
                                        |> T.map
                                            (\result ->
                                                case result of
                                                    Ok res ->
                                                        Throw "reslut test"

                                                    -- SetSelectableCameras [ "f", "t" ]
                                                    Err err ->
                                                        Throw "okoko"
                                            )
                                        |> unwrapTask
                                )
                    )
                |> unwrapTask
    in
    ( { cameraH = Nothing, error = Nothing, selectableCameras = [] }, getCameraListTask )


view : Model -> Html.Html Msg
view model =
    let
        html =
            case model.selectableCameras of
                [] ->
                    Html.text "no camera"

                _ ->
                    Html.text "camera list"
    in
    Html.div []
        --     Html.button [ onClick (OpenCamera "test_path") ] [ Html.text "Open Camera" ]
        -- , model.error
        --     |> Maybe.map (\error -> Html.text ("Error: " ++ error))
        --     |> Maybe.withDefault (Html.text "no error")
        --     (model.selectableCameras
        --     |> List.map (\camera -> Html.text camera)
        --  )
        [ model.cameraH |> Maybe.map (\camH -> Html.text "has camera") |> Maybe.withDefault (Html.text "no camera") ]



-- [ html, model.error |> Maybe.map (\error -> Html.text ("Error: " ++ error)) |> Maybe.withDefault (Html.text "no error") ]
-- [ Html.text (Maybe.withDefault "no camera" (Maybe.Just "test")) ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCameraH cameraH ->
            ( { model | cameraH = Just cameraH }, Cmd.none )

        -- GetCameraH f ->
        --     case Maybe.map f model.cameraH of
        --         Just cmd ->
        --             ( model, cmd )
        --         Nothing ->
        --             ( model, Cmd.none )
        GetCameraH f ->
            case Maybe.map f model.cameraH of
                Just cmd ->
                    ( model, T.succeed (Throw "fff") |> unwrapTask )

                Nothing ->
                    ( model, T.succeed (Throw "ggg") |> unwrapTask )

        SetSelectableCameras cameras ->
            ( { model | selectableCameras = cameras }, Cmd.none )

        -- SetSelectableCameras cameras ->
        --     ( { model | selectableCameras = cameras }, Cmd.none )
        Throw error ->
            ( { model | error = Just error }, Cmd.none )

        None ->
            ( model, Cmd.none )


subscriptions model =
    Sub.none


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> Throw)
        |> T.attempt R.merge
