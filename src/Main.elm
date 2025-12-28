port module Main exposing (..)

-- import Css

import Browser
import Grpc
import Html exposing (Html, button, div, form, h1, h2, h3, header, label, optgroup, option, p, section, select, text)
import Html.Attributes as Attribute exposing (class, selected, style)
import Html.Events exposing (onInput)
import Proto.Camera exposing (defaultGetCameraListRequest)
import Proto.Camera.CameraService exposing (getCameraList)
import Svg as S
import Svg.Attributes as SA
import Task


port testReceiver : (String -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { counter : Int
    , message : String
    , cameraList : List String
    }


type Msg
    = Select String
    | GotCameraList (Result Grpc.Error Proto.Camera.GetCameraListResponse)
    | Recv String


init : () -> ( Model, Cmd Msg )
init () =
    let
        task =
            Grpc.new getCameraList defaultGetCameraListRequest
                |> Grpc.setHost "http://localhost:50051"
                |> Grpc.toTask
                |> Task.attempt GotCameraList
    in
    ( { counter = 0, message = "", cameraList = [] }, task )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Select value ->
            ( { model | message = value }, Cmd.none )

        GotCameraList result ->
            case result of
                Ok response ->
                    ( { model | cameraList = response.cameraList }, Cmd.none )

                Err error ->
                    ( { model | message = "some error" }, Cmd.none )

        Recv recv ->
            ( { model | message = recv }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "overflow-hidden" ]
        -- [ div [ class "flex  h-screen overflow-hidden" ]
        --     [ --     selectView model.cameraList |> Html.map Select
        --       -- , buttonView ()
        --       div [ class "card w-3/4 p-6 m-3 flex flex-col items-center" ]
        --         [ p [ class "text-xs mt-1" ] [ text "カメラソースを選択してください" ] ]
        --     , div [ class "card w-1/4 px-4 pb-4 pt-4 m-3 flex flex-col" ]
        --         [ h2 [ class "text-left text-lg font-semibold" ] [ text "設定" ]
        --         , -- ,
        --           div [ class "w-full grid gap-2" ]
        --             [ section [ class "flex flex-col gap-2" ]
        --                 [ label [ class "label" ] [ text "入力デバイス" ]
        --                 , selectView model.cameraList |> Html.map Select
        --                 ]
        --             ]
        --         ]
        --     ]
        -- ]
        [ text model.message
        , div [ class "flex gap-2 p-2 h-screen" ]
            [ --     selectView model.cameraList |> Html.map Select
              -- , buttonView ()
              div [ class "card w-3/4 p-6 flex flex-col items-center" ]
                [ p [ class "text-xs mt-1" ] [ text "カメラソースを選択してください" ] ]
            , div [ class "card w-1/4 px-4 pb-4 pt-4 flex flex-col" ]
                [ div [ class "flex items-center gap-2" ]
                    [ S.svg
                        [ SA.xmlBase "http://www.w3.org/2000/svg"
                        , SA.width "24"
                        , SA.height "24"
                        , SA.viewBox "0 0 24 24"
                        , SA.fill "none"
                        , SA.stroke "currentColor"
                        , SA.strokeWidth "2"
                        , SA.strokeLinecap "round"
                        , SA.strokeLinejoin "round"
                        , SA.class "lucide lucide-settings2-icon lucide-settings-2"
                        ]
                        [ S.circle [ SA.cx "17", SA.cy "17", SA.r "3" ] []
                        , S.circle [ SA.cx "7", SA.cy "7", SA.r "3" ] []
                        , S.path [ SA.d "M14 17H5" ] []
                        , S.path [ SA.d "M19 7h-9" ] []
                        ]
                    , h2 [ class "text-left text-lg font-semibold" ]
                        [ text "設定"
                        ]
                    ]
                , -- ,
                  div [ class "w-full grid gap-2" ]
                    [ section [ class "flex flex-col gap-2" ]
                        [ label [ class "label" ] [ text "入力デバイス" ]
                        , selectView model.cameraList |> Html.map Select
                        ]
                    ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    testReceiver Recv


selectView : List String -> Html String
selectView options =
    select [ class "select w-full", onInput identity ]
        (options
            |> List.map (text >> List.singleton >> option [])
        )


buttonView () =
    button [ class "btn-secondary" ] [ text "Open" ]
