module Main exposing (..)

-- import Css exposing (..)
-- import Html.Styled
-- import Material.Icons as MaterialIcons
-- import Html.Grid as Grid

import Browser
import Browser.Dom exposing (Element)
import Browser.Events exposing (onAnimationFrame, onAnimationFrameDelta)
import CameraHandler exposing (Camera, CameraHandler, GetCameraImageResponseJson, getCameraList)
import Cmd.Extra as C
import Css exposing (..)
import Do.Task as T
import Element
import Element.Input as Input
import Framework.Grid as LayoutGrid
import Framework.Input as Input
import Framework.Slider as Slider
import Html as H
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Html.Styled as HS exposing (toUnstyled)
import Html.Styled.Attributes as HS
import Json.Decode as D
import Json.Encode as E
import Material.Button as Button
import Material.IconButton as IconButton exposing (Icon, icon)
import Material.Icons.Action
import Material.LayoutGrid as LayoutGrid
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Typography as Typography
import Result as R
import Result.Extra as R
import Task as T
import TaskPort as TP
import WebSocket exposing (WebSocket)
import Widget
import Widget.Icon as Icon exposing (Icon)
import Widget.Material as Material


type Model
    = Init
    | Normal
        { cameraH : CameraHandler
        , availableCameraList : List String
        , selectedCamera : Maybe String
        , openedCamera : Maybe Camera
        , currentImage : List Int
        , virtualCameraName : Maybe String
        , virtualCameraResolution : Int
        }
    | FatalError String
    | UnreachableS String


type Msg
    = OpenCameraClick
    | CameraSelect String
    | SetVirtualCameraName String
    | SetVirtualCameraResolution Int
    | Publish
    | InitCameraH CameraHandler
    | GetCameraImage
    | GotCameraImage GetCameraImageResponseJson
    | GetAvailableCameraList
    | GotAvailableCameraList CameraHandler.GetCameraListResponse
    | GotCamera Camera
    | FatalException String
    | Unreachable String


main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initCameraHandler =
            CameraHandler.new ()
                |> T.map InitCameraH
                |> unwrapTask
    in
    ( Init
    , initCameraHandler
    )


card : List (Element.Element Msg) -> Element.Element Msg
card itemList =
    Widget.column
        (Material.cardColumn Material.defaultPalette)
        itemList



-- configView : Model -> Element.Element Msg


configView model_ =
    let
        inputView text =
            { chips = []
            , text = text
            , placeholder = Nothing
            , label = ""
            , onChange = SetVirtualCameraName
            }
                |> Widget.textInput (Material.textInput Material.defaultPalette)
    in
    -- card
    [ -- Element.el [ Element.alignLeft ] <|
      -- Widget.button (Material.containedButton Material.defaultPalette)
      --     { text = "PUBLISH"
      --     , onPress = Just OpenCameraClick
      --     , icon =
      --         always Element.none
      --     }
      "VirtualCameraName" |> Widget.headerItem (Material.fullBleedHeader Material.defaultPalette)
    , inputView (Maybe.withDefault "" model_.virtualCameraName) |> Widget.asItem
    , "Resolution" |> Widget.headerItem (Material.fullBleedHeader Material.defaultPalette)
    , Input.slider Slider.simple
        { onChange = Basics.round >> SetVirtualCameraResolution
        , label = Input.labelRight Input.label <| Element.el [ Element.alignRight ] <| Element.text ((model_.virtualCameraResolution |> String.fromInt) ++ " p")
        , value = model_.virtualCameraResolution |> Basics.toFloat
        , min = 160
        , max = 1080
        , thumb = Input.thumb Slider.thumb
        , step = Nothing
        }
        |> Widget.asItem
    , Widget.button (Material.containedButton Material.defaultPalette)
        { text = "PUBLISH"
        , onPress = Just Publish
        , icon =
            always Element.none
        }
        |> Element.el [ Element.alignRight ]
        |> Widget.asItem
    ]
        |> Widget.itemList (Material.cardColumn Material.defaultPalette)


view : Model -> H.Html Msg
view model_ =
    case model_ of
        Init ->
            H.div [] []

        Normal model ->
            Element.column []
                [ Element.row [ Element.spacing 16 ]
                    [ Element.el []
                        (Select.filled
                            (Select.config
                                |> Select.setLabel (Just "Camera Source")
                                |> Select.setSelected model.selectedCamera
                                |> Select.setOnChange CameraSelect
                            )
                            (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
                            (model.availableCameraList
                                |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
                            )
                            |> Element.html
                        )
                    , Element.el [] <|
                        Widget.button (Material.containedButton Material.defaultPalette)
                            { text = "Open"
                            , onPress = Just OpenCameraClick
                            , icon =
                                Material.Icons.Action.open_in_browser
                                    |> Icon.materialIcons
                            }
                    ]
                , canvas model.currentImage |> List.singleton |> card
                , configView model
                ]
                |> Element.layout []

        FatalError error ->
            H.div [] [ H.text error ]

        UnreachableS error ->
            H.div [] [ H.text error ]



-- view : Model -> H.Html Msg
-- view model_ =
--     configView model_
-- [ W.itemList (Material.cardColumn Material.defaultPalette)
--     [ W.insetItem (Material.insetItem Material.defaultPalette)
--         { text = "Open Camera", onPress = Nothing, icon = always Element.none, content = always Element.none }
--     , W.button
--         (W.containedButton W.defaultPalette)
--         { text = "Open Camera"
--         , onPress = Just OpenCameraClick
--         , icon =
--             Material.Icons.Action.done
--                 |> Icon.materialIcons
--         }
--     ]
-- ]
-- )
-- (W.button
--     (W.containedButton W.defaultPalette)
--     { text = "Open Camera"
--     , onPress = Just OpenCameraClick
--     , icon =
--         Material.Icons.Action.done
--             |> Icon.materialIcons
--     }
-- )
-- view : Model -> H.Html Msg
-- view model_ =
--     case model_ of
--         Init ->
--             H.div [] []
--         -- H.div [] [ Widget.button (Material.containedButton Material.defaultPalette) { text = "Open Camera", onPress = Nothing, icon = Just "launch" } ]
--         Normal model ->
--             H.div [ HA.style "width" "100%", HA.style "height" "100vh", HA.style "display" "block", HA.style "overflow" "hidden" ]
--                 [ Select.filled
--                     (Select.config
--                         |> Select.setLabel (Just "Camera Source")
--                         |> Select.setSelected model.selectedCamera
--                         |> Select.setOnChange CameraSelect
--                     )
--                     (SelectItem.selectItem (SelectItem.config { value = "None" }) "None")
--                     (model.availableCameraList
--                         |> List.map (\camera -> SelectItem.selectItem (SelectItem.config { value = camera }) camera)
--                     )
--                 , IconButton.iconButton
--                     (IconButton.config |> IconButton.setOnClick OpenCameraClick)
--                     (IconButton.icon "launch")
--                 , Element.row [] [ Element.el [] [] ]
--                 -- , Grid.box
--                 --     [ width (pct 100), height (pct 100) ]
--                 --     [ Grid.row
--                 --         [ width (pct 100), height (pct 100) ]
--                 --         [ Grid.col
--                 --             [ Grid.exactWidthCol (pct 70), height (pct 100) ]
--                 --             [ canvas model.currentImage ]
--                 --         , Grid.col
--                 --             []
--                 --             [
--                 --              ]
--                 --         ]
--                 --     ]
--                 --     |> toUnstyled
--                 ]
--         FatalError error ->
--             H.div [] [ H.text error ]
--         UnreachableS error ->
--             H.div [] [ H.text error ]


canvas bytes =
    H.node "elm-canvas"
        [ HA.property "bytes" (E.list E.int bytes)
        , HA.attribute "style" "width: 100%; height: 100%; display: block;"
        ]
        [ H.div [ HA.attribute "style" "width: 100%; height: 100%; display: block;" ]
            [ H.canvas [ HA.id "canvas" ] []
            ]
        ]
        |> Element.html


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model_ =
    case model_ of
        Init ->
            case msg of
                InitCameraH initCameraH ->
                    ( Normal
                        { cameraH = initCameraH
                        , availableCameraList = []
                        , selectedCamera = Nothing
                        , openedCamera = Nothing
                        , currentImage = []
                        , virtualCameraName = Nothing
                        , virtualCameraResolution = 1080
                        }
                    , C.perform GetAvailableCameraList
                    )

                _ ->
                    ( Init, C.perform (Unreachable "failed to initialize camera handler") )

        Normal model ->
            case msg of
                OpenCameraClick ->
                    case model.selectedCamera of
                        Just cameraName ->
                            let
                                task =
                                    CameraHandler.open model.cameraH cameraName
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCamera)
                                        |> unwrapTask
                            in
                            ( model_, task )

                        _ ->
                            ( model_, C.perform (Unreachable "failed to open camera") )

                SetVirtualCameraName name ->
                    ( Normal { model | virtualCameraName = Just name }, Cmd.none )

                SetVirtualCameraResolution resolution ->
                    ( Normal { model | virtualCameraResolution = resolution }, Cmd.none )

                Publish ->
                    ( model_, Cmd.none )

                CameraSelect cameraName ->
                    ( Normal { model | selectedCamera = Just cameraName }, Cmd.none )

                GotCamera camera ->
                    ( Normal { model | openedCamera = Just camera }, C.perform GetCameraImage )

                GetCameraImage ->
                    case model.openedCamera of
                        Just openedCameraJ ->
                            let
                                task =
                                    CameraHandler.getCameraImage model.cameraH openedCameraJ
                                        |> T.map (R.unpack (D.errorToString >> FatalException) GotCameraImage)
                                        |> unwrapTask
                            in
                            ( model_, task )

                        Nothing ->
                            ( model_, C.perform (FatalException "Camera not opened") )

                GotCameraImage res ->
                    ( Normal { model | currentImage = res.image }, C.perform GetCameraImage )

                InitCameraH _ ->
                    ( Normal model, C.perform (Unreachable "camera handler is already initialized") )

                GetAvailableCameraList ->
                    let
                        task =
                            getCameraList model.cameraH
                                |> T.map (R.unpack (D.errorToString >> FatalException) GotAvailableCameraList)
                                |> unwrapTask
                    in
                    ( Normal model, task )

                GotAvailableCameraList res ->
                    ( Normal { model | availableCameraList = res.cameras }, Cmd.none )

                FatalException error ->
                    ( FatalError error, Cmd.none )

                Unreachable error ->
                    ( UnreachableS error, Cmd.none )

        _ ->
            ( model_, Cmd.none )


subscriptions model =
    Sub.none


unwrapTask task =
    task
        |> T.mapError (TP.errorToString >> FatalException)
        |> T.attempt R.merge
