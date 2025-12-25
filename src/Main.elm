module Main exposing (..)

-- import Css

import Browser
import Grpc
import Html exposing (Html, button, div, form, label, optgroup, option, select, text)
import Html.Attributes as Attribute exposing (class, selected)
import Html.Events exposing (onInput)
import Proto.Camera exposing (defaultGetCameraListRequest)
import Proto.Camera.CameraService exposing (getCameraList)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { counter : Int
    , message : String
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { counter = 0, message = "" }, Cmd.none )


type Msg
    = Select String
    | GetCameraList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Select value ->
            ( { model | message = value }, Cmd.none )

        GetCameraList ->
            let
                _ =
                    Grpc.new getCameraList defaultGetCameraListRequest
                        |> Grpc.setHost "http://localhost:8080"

                -- Grpc
            in
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [] [ selectView [ "Hello", "World" ] |> Html.map Select ]


selectView : List String -> Html String
selectView options =
    select [ class "select w-[180px]", onInput identity ]
        [ optgroup []
            (options
                |> List.map (text >> List.singleton >> option [])
            )
        ]
