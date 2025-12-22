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


type alias OpenCameraJson =
    { name : String }


encodeOpenCameraJson : OpenCameraJson -> E.Value
encodeOpenCameraJson packet =
    E.object
        [ ( "OpenCamera", E.object [ ( "name", E.string packet.name ) ] )
        ]


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


openCameraQuery name ws =
    WS.sendWebSocket ws (encodeOpenCameraJson { name = name })


new : () -> T.Task TP.Error CameraHandler
new _ =
    WS.open "ws://localhost:8000/ws"
        |> T.map (\ws -> CameraHandler ws "test camera name handler")



-- open : String -> T.Task TP.Error Camera
-- open name =
--     WS.open "ws://localhost:8000/ws"
--         |> T.map
--             (\ws ->
--                 let
--                     _ =
--                         openCameraQuery name ws
--                 in
--                 ws
--             )
--         |> T.map (\ws -> Camera ws name)


getCameraListQuery ws =
    WS.sendWebSocket ws (encodeGetCameraListJson {})


getCameraList : CameraHandler -> T.Task TP.Error (Result D.Error GetCameraListResponse)
getCameraList camH =
    getCameraListQuery camH.ws
        |> T.map (\q -> D.decodeValue decodeGetCameraListResponse q.message)
