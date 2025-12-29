module Main exposing (..)

import Browser
import Html exposing (Html, text)


type alias Model =
    ()


type Msg
    = NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    ( (), Cmd.none )


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
    text "Hello World"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
