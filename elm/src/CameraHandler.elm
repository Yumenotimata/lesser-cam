module CameraHandler exposing (..)

import Json.Decode as D
import Json.Encode as E
import Result as R
import Result.Extra as R
import String exposing (String)
import Task as T
import TaskPort as TP
import WebSocket as WS


type alias CameraHandler =
    { ws : WS.WebSocket, name : String }


type alias GetCameraListJson =
    {}


type alias GetCameraListResponse =
    { cameras : List String }


encodeGetCameraListJson : GetCameraListJson -> E.Value
encodeGetCameraListJson packet =
    E.object
        [ ( "GetCameraList", E.object [] )
        ]


decodeGetCameraListResponse : D.Decoder GetCameraListResponse
decodeGetCameraListResponse =
    D.map GetCameraListResponse
        (D.field "CameraList" (D.list D.string))


new : () -> T.Task TP.Error CameraHandler
new _ =
    WS.open "ws://localhost:8000/ws"
        |> T.map (\ws -> CameraHandler ws "test camera name handler")


getCameraListQuery ws =
    WS.sendWebSocket ws (encodeGetCameraListJson {})


getCameraList : CameraHandler -> T.Task TP.Error (Result D.Error GetCameraListResponse)
getCameraList camH =
    getCameraListQuery camH.ws
        |> T.map (\q -> D.decodeValue decodeGetCameraListResponse q.message)


type alias Camera =
    { uuid : Int }


type alias OpenCameraRequestJson =
    { name : String }


encodeOpenCameraRequestJson : OpenCameraRequestJson -> E.Value
encodeOpenCameraRequestJson packet =
    E.object
        [ ( "OpenCamera", E.object [ ( "name", E.string packet.name ) ] )
        ]


type alias OpenCameraResponseJson =
    { uuid : Int }


decodeOpenCameraResponseJson : D.Decoder OpenCameraResponseJson
decodeOpenCameraResponseJson =
    D.map OpenCameraResponseJson
        (D.field "Camera" D.int)


openCameraQuery : WS.WebSocket -> String -> T.Task TP.Error WS.SendWebSocketJson
openCameraQuery ws name =
    WS.sendWebSocket ws (encodeOpenCameraRequestJson { name = name })


open camH name =
    openCameraQuery camH.ws name
        |> T.map (.message >> D.decodeValue decodeOpenCameraResponseJson)
        |> T.map (R.map (\r -> { uuid = r.uuid }))


type alias GetCameraImageJson =
    { uuid : Int }


encodeGetCameraImageJson : GetCameraImageJson -> E.Value
encodeGetCameraImageJson packet =
    E.object
        [ ( "GetCameraImage", E.object [ ( "uuid", E.int packet.uuid ) ] )
        ]


type alias GetCameraImageResponseJson =
    { image : List Int }


decodeGetCameraImageResponseJson : D.Decoder GetCameraImageResponseJson
decodeGetCameraImageResponseJson =
    D.map GetCameraImageResponseJson
        (D.field "CameraImage" (D.list D.int))


getCameraImageQuery : WS.WebSocket -> Int -> T.Task TP.Error WS.SendWebSocketJson
getCameraImageQuery ws uuid =
    WS.sendWebSocket ws (encodeGetCameraImageJson { uuid = uuid })


getCameraImage camH camera =
    getCameraImageQuery camH.ws camera.uuid
        |> T.map (.message >> D.decodeValue decodeGetCameraImageResponseJson)
