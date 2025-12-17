module Main exposing (..)

import Browser
import Html


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init () =
    ( 0, Cmd.none )


view model =
    Html.div [] []


update msg model =
    ( model, Cmd.none )


subscriptions model =
    Sub.none
