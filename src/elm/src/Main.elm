module Main exposing (..)

-- import Css

import Browser
import Bytes exposing (Endianness(..))
import Bytes.Decode as Decode
import Cmd.Extra as Cmd
import Grpc
import Html exposing (Html, button, canvas, div, form, h1, h2, h3, header, input, label, node, optgroup, option, p, section, select, text)
import Html.Attributes as Attr exposing (attribute, class, id, property, selected, style)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (map)
import Json.Encode as E
import Maybe exposing (withDefault)
import Proto.Camera exposing (GetCameraListResponse, GetLatestCameraFrameResponse, defaultGetCameraListRequest, defaultGetLatestCameraFrameRequest)
import Proto.Camera.CameraService exposing (getCameraList, getLatestCameraFrame, publishVirtualCamera, unpublishVirtualCamera)
import String exposing (isEmpty)
import Svg as S exposing (svg)
import Svg.Attributes as SA
import Task
import Time


type alias CameraId =
    { name : String, id : Int }


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
    , cameraList : List CameraId
    , selectedCamera : Maybe CameraId
    , virtualCameraConfig : Proto.Camera.VirtualCameraConfig
    , isVirtualCamera : Bool
    , publishVirtualCamera : Bool
    }


type Msg
    = Select String
    | GotCameraList (Result Grpc.Error GetCameraListResponse)
    | OnResolutionChange Float
      -- | SetVirtualCameraConfig
    | ToggleIsVirtualCamera
    | TogglePublishVirtualCamera
    | NoOp


init : () -> ( Model, Cmd Msg )
init () =
    let
        task =
            Grpc.new getCameraList defaultGetCameraListRequest
                |> Grpc.setHost "http://localhost:50051"
                |> Grpc.toTask
                |> Task.attempt GotCameraList
    in
    ( { counter = 0
      , message = ""
      , cameraList = []
      , selectedCamera = Nothing
      , virtualCameraConfig = { resolutionRatio = 1 }
      , isVirtualCamera = False
      , publishVirtualCamera = False
      }
    , task
    )


rpcCameraViewer rpcUrl cameraId isVirtualCamera =
    node "elm-canvas"
        [ property "rpcUrl" (E.string rpcUrl)
        , property "cameraId" (encodeCameraId cameraId)
        , property "isVirtualCamera" (E.bool isVirtualCamera)
        , attribute "style" "width: 100%; height: 100%; display: block;"
        ]
        [ div [ class "w-full h-full" ]
            [ canvas [ id "canvas", style "width" "100%", style "height" "100%" ] []
            ]
        ]


encodeCameraId : CameraId -> E.Value
encodeCameraId cameraId =
    E.object
        [ ( "name", E.string cameraId.name )
        , ( "id", E.int cameraId.id )
        ]


onFloatEvent : String -> (Float -> msg) -> Html.Attribute msg
onFloatEvent eventName floatMsg =
    let
        inputText2FloatMsg : String -> msg
        inputText2FloatMsg inputText =
            floatMsg <| Maybe.withDefault 0.0 <| String.toFloat <| inputText
    in
    Html.Events.targetValue
        |> map inputText2FloatMsg
        |> Html.Events.on eventName


onFloatChange : (Float -> msg) -> Html.Attribute msg
onFloatChange floatMsg =
    onFloatEvent "change" floatMsg


onFloatInput : (Float -> msg) -> Html.Attribute msg
onFloatInput floatMsg =
    onFloatEvent "input" floatMsg


sliderFloatView min max step value change =
    Html.input
        [ Attr.type_ "range"
        , Attr.min <| String.fromFloat min
        , Attr.max <| String.fromFloat max
        , Attr.step <| String.fromFloat step

        -- , Attr.value <| String.fromFloat value
        -- , style "--slider-value" ("60" ++ "%")
        , onFloatChange change
        , onFloatInput change

        -- , property "--slider-value" (E.string ("60" ++ "%"))
        , class "input w-full"
        ]
        []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Select value ->
            if isEmpty value then
                ( { model | selectedCamera = Nothing }, Cmd.none )

            else
                case List.filter (\camera -> camera.name == value) model.cameraList of
                    [] ->
                        ( model, Cmd.none )

                    camera :: _ ->
                        ( { model | selectedCamera = Just camera }, Cmd.none )

        GotCameraList result ->
            case result of
                Ok response ->
                    let
                        task =
                            case List.head response.cameraList of
                                Just camera ->
                                    Cmd.perform <| Select camera.name

                                Nothing ->
                                    Cmd.none
                    in
                    ( { model | cameraList = response.cameraList }, task )

                Err error ->
                    ( { model | message = "some error" }, Cmd.none )

        OnResolutionChange value ->
            let
                oldConfig =
                    model.virtualCameraConfig
            in
            let
                newConfig =
                    { oldConfig | resolutionRatio = value / 100 }
            in
            ( { model | virtualCameraConfig = newConfig }, Cmd.none )

        ToggleIsVirtualCamera ->
            ( { model | isVirtualCamera = not model.isVirtualCamera }, Cmd.none )

        TogglePublishVirtualCamera ->
            case model.selectedCamera of
                Just cameraName ->
                    let
                        nextIsPublish =
                            not model.publishVirtualCamera
                    in
                    let
                        task =
                            if nextIsPublish then
                                Grpc.new publishVirtualCamera { cameraId = Just cameraName, config = Just model.virtualCameraConfig }
                                    |> Grpc.setHost "http://localhost:50051"
                                    |> Grpc.toTask
                                    |> Task.attempt (always NoOp)

                            else
                                Grpc.new unpublishVirtualCamera { cameraId = Just cameraName }
                                    |> Grpc.setHost "http://localhost:50051"
                                    |> Grpc.toTask
                                    |> Task.attempt (always NoOp)
                    in
                    ( { model | publishVirtualCamera = nextIsPublish }, task )

                Nothing ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


sizedString : Decode.Decoder String
sizedString =
    Decode.unsignedInt8
        |> Decode.andThen Decode.string


view : Model -> Html Msg
view model =
    div [ class "flex w-screen h-screen overflow-hidden" ]
        [ div
            [ class "flex w-full h-full gap-2 p-2" ]
            [ div
                [ class "card bg-black w-3/4 h-full p-0 flex items-center justify-center relative" ]
                [ button [ class "btn bg-black absolute top-2 right-2", onClick ToggleIsVirtualCamera ]
                    [ svg
                        [ SA.xmlBase "http://www.w3.org/2000/svg"
                        , SA.fill "none"
                        , SA.viewBox "0 0 24 24"
                        , SA.strokeWidth "1.5"
                        , SA.stroke "currentColor"
                        , SA.class "size-6"
                        ]
                        [ S.path
                            [ SA.strokeLinecap "round"
                            , SA.strokeLinejoin "round"
                            , SA.d "M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
                            ]
                            []
                        ]
                    ]
                , case model.selectedCamera of
                    Nothing ->
                        p [ class "text-xs" ] [ text "カメラソースを選択してください" ]

                    Just camera ->
                        div [ class "w-full h-full flex items-center justify-center" ]
                            [ rpcCameraViewer "http://localhost:50051" camera model.isVirtualCamera ]
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
                , div [ class "w-ful h-full flex flex-col gap-4" ]
                    [ section [ class "flex flex-col gap-2" ]
                        [ label [ class "label" ] [ text "入力デバイス" ]
                        , selectView (List.map .name model.cameraList) |> Html.map Select
                        ]
                    , section [ class "flex flex-col gap-2" ]
                        [ label [ class "label" ] [ text "解像度" ]
                        , form [ class "form" ] [ sliderFloatView 0.0 100.0 1.0 model.virtualCameraConfig.resolutionRatio OnResolutionChange ]
                        ]
                    , div [ class "mt-auto" ]
                        [ if model.publishVirtualCamera then
                            button
                                [ class "btn-destructive w-full"
                                , onClick TogglePublishVirtualCamera
                                ]
                                [ p [ class "text-white" ] [ text "Unpublish" ] ]

                          else
                            button
                                [ class "btn-secondary w-full bg-blue-600"
                                , onClick TogglePublishVirtualCamera
                                ]
                                [ p [ class "text-white" ] [ text "Publish" ] ]
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
