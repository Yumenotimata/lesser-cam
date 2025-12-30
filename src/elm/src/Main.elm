-- module Main exposing (..)
-- -- import Css
-- import Browser
-- import Bytes exposing (Endianness(..))
-- import Bytes.Decode as Decode
-- import Grpc
-- import Html exposing (Html, button, canvas, div, form, h1, h2, h3, header, label, node, optgroup, option, p, section, select, text)
-- import Html.Attributes as Attribute exposing (attribute, class, id, property, selected, style)
-- import Html.Events exposing (onInput)
-- import Json.Encode as E
-- import Maybe exposing (withDefault)
-- import Proto.Camera exposing (GetCameraListResponse, GetLatestCameraFrameResponse, defaultGetCameraListRequest, defaultGetLatestCameraFrameRequest)
-- import Proto.Camera.CameraService exposing (getCameraList, getLatestCameraFrame)
-- import String exposing (isEmpty)
-- import Svg as S
-- import Svg.Attributes as SA
-- import Task
-- import Time
-- main : Program () Model Msg
-- main =
--     Browser.element
--         { init = init
--         , update = update
--         , view = view
--         , subscriptions = subscriptions
--         }
-- type alias Model =
--     { counter : Int
--     , message : String
--     , cameraList : List String
--     , selectedCamera : Maybe String
--     }
-- type Msg
--     = Select String
--     | GotCameraList (Result Grpc.Error GetCameraListResponse)
-- init : () -> ( Model, Cmd Msg )
-- init () =
--     let
--         task =
--             Grpc.new getCameraList defaultGetCameraListRequest
--                 |> Grpc.setHost "http://localhost:50051"
--                 |> Grpc.toTask
--                 |> Task.attempt GotCameraList
--     in
--     ( { counter = 0, message = "", cameraList = [], selectedCamera = Nothing }, task )
-- rpcCameraViewer rpcUrl cameraName =
--     node "elm-canvas"
--         [ attribute "rpcUrl" rpcUrl
--         , attribute "cameraName" cameraName
--         --     property "rpcUrl" (E.string rpcUrl)
--         -- , property "cameraName" (E.string cameraName)
--         , attribute "style" "width: 100%; height: 100%; display: block;"
--         ]
--         [ div [ class "w-full h-full" ]
--             [ canvas [ id "canvas", Attribute.style "width" "100%", Attribute.style "height" "100%" ] []
--             ]
--         ]
-- update : Msg -> Model -> ( Model, Cmd Msg )
-- update msg model =
--     case msg of
--         Select value ->
--             if isEmpty value then
--                 ( { model | selectedCamera = Nothing }, Cmd.none )
--             else
--                 ( { model | selectedCamera = Just value }, Cmd.none )
--         GotCameraList result ->
--             case result of
--                 Ok response ->
--                     ( { model | cameraList = response.cameraList }, Cmd.none )
--                 Err error ->
--                     ( { model | message = "some error" }, Cmd.none )
-- sizedString : Decode.Decoder String
-- sizedString =
--     Decode.unsignedInt8
--         |> Decode.andThen Decode.string
-- view : Model -> Html Msg
-- view model =
--     div [ class "flex w-screen h-screen overflow-hidden" ]
--         [ text (withDefault "no camera" model.selectedCamera)
--         , div [ class "flex w-full h-full gap-2 p-2" ]
--             [ div
--                 [ class "card flex w-3/4 h-full p-6 items-center justify-center" ]
--                 [ case model.selectedCamera of
--                     Nothing ->
--                         p [ class "text-xs" ] [ text "カメラソースを選択してください" ]
--                     Just cameraName ->
--                         div [ class "w-full h-full flex items-center justify-center" ]
--                             [ rpcCameraViewer "http://localhost:50051" cameraName ]
--                 ]
--             , div [ class "card w-1/4 px-4 pb-4 pt-4 flex flex-col" ]
--                 [ div [ class "flex items-center gap-2" ]
--                     [ S.svg
--                         [ SA.xmlBase "http://www.w3.org/2000/svg"
--                         , SA.width "24"
--                         , SA.height "24"
--                         , SA.viewBox "0 0 24 24"
--                         , SA.fill "none"
--                         , SA.stroke "currentColor"
--                         , SA.strokeWidth "2"
--                         , SA.strokeLinecap "round"
--                         , SA.strokeLinejoin "round"
--                         , SA.class "lucide lucide-settings2-icon lucide-settings-2"
--                         ]
--                         [ S.circle [ SA.cx "17", SA.cy "17", SA.r "3" ] []
--                         , S.circle [ SA.cx "7", SA.cy "7", SA.r "3" ] []
--                         , S.path [ SA.d "M14 17H5" ] []
--                         , S.path [ SA.d "M19 7h-9" ] []
--                         ]
--                     , h2 [ class "text-left text-lg font-semibold" ]
--                         [ text "設定"
--                         ]
--                     ]
--                 , div [ class "w-full grid gap-2" ]
--                     [ section [ class "flex flex-col gap-2" ]
--                         [ label [ class "label" ] [ text "入力デバイス" ]
--                         , selectView model.cameraList |> Html.map Select
--                         ]
--                     ]
--                 ]
--             ]
--         ]
-- subscriptions : Model -> Sub Msg
-- subscriptions model =
--     Sub.none
-- selectView : List String -> Html String
-- selectView options =
--     select [ class "select w-full", onInput identity ]
--         (options
--             |> List.map (text >> List.singleton >> option [])
--         )
-- buttonView () =
--     button [ class "btn-secondary" ] [ text "Open" ]


port module Main exposing (..)

-- import Css

import Browser
import Bytes exposing (Endianness(..))
import Bytes.Decode as Decode
import Grpc
import Html exposing (Html, button, canvas, div, form, h1, h2, h3, header, label, node, optgroup, option, p, section, select, text)
import Html.Attributes as Attribute exposing (attribute, class, id, property, selected, style)
import Html.Events exposing (onInput)
import Json.Encode as E
import Proto.Camera exposing (GetCameraListResponse, GetLatestCameraFrameResponse, defaultGetCameraListRequest, defaultGetLatestCameraFrameRequest)
import Proto.Camera.CameraService exposing (getCameraList, getLatestCameraFrame)
import String exposing (isEmpty)
import Svg as S
import Svg.Attributes as SA
import Task
import Time


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
    , selectedCamera : Maybe String
    }


type Msg
    = Select String
    | GotCameraList (Result Grpc.Error GetCameraListResponse)


init : () -> ( Model, Cmd Msg )
init () =
    let
        task =
            Grpc.new getCameraList defaultGetCameraListRequest
                |> Grpc.setHost "http://localhost:50051"
                |> Grpc.toTask
                |> Task.attempt GotCameraList
    in
    ( { counter = 0, message = "", cameraList = [], selectedCamera = Nothing }, task )


rpcCameraViewer rpcUrl cameraName =
    node "elm-canvas"
        [ property "rpcUrl" (E.string rpcUrl)
        , property "cameraName" (E.string cameraName)
        , attribute "style" "width: 100%; height: 100%; display: block;"
        ]
        [ div [ class "w-full h-full" ]
            [ canvas [ id "canvas", Attribute.style "width" "100%", Attribute.style "height" "100%" ] []
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Select value ->
            if isEmpty value then
                ( { model | selectedCamera = Nothing }, Cmd.none )

            else
                ( { model | selectedCamera = Just value }, Cmd.none )

        GotCameraList result ->
            case result of
                Ok response ->
                    ( { model | cameraList = response.cameraList }, Cmd.none )

                Err error ->
                    ( { model | message = "some error" }, Cmd.none )


sizedString : Decode.Decoder String
sizedString =
    Decode.unsignedInt8
        |> Decode.andThen Decode.string


view : Model -> Html Msg
view model =
    div [ class "flex w-screen h-screen overflow-hidden" ]
        [ text model.message
        , div [ class "flex w-full h-full gap-2 p-2" ]
            [ -- , buttonView ()
              div
                [ class "card flex w-3/4 h-full p-6 items-center justify-center" ]
                [ case model.selectedCamera of
                    Nothing ->
                        p [ class "text-xs" ] [ text "カメラソースを選択してください" ]

                    Just cameraName ->
                        div [ class "w-full h-full flex items-center justify-center" ]
                            [ rpcCameraViewer "http://localhost:50051" cameraName ]
                ]
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
                , div [ class "w-full grid gap-2" ]
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
    Sub.none


selectView : List String -> Html String
selectView options =
    select [ class "select w-full", onInput identity ]
        (options
            |> List.map (text >> List.singleton >> option [])
        )


buttonView () =
    button [ class "btn-secondary" ] [ text "Open" ]
