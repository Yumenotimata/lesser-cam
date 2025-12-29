port module Main exposing (..)

import Browser
import Html exposing (Html, text, div)
import Html.Attributes exposing (class)

port tauri : String -> Cmd msg

type alias Model =
    ()


type Msg
    = NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    ( (), tauri "Hello, Elm" )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


view : Model -> Html Msg
view model =
    div [ class "btn" ] [ text "Hello Elm" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
