module Camera exposing (..)

import Json.Encode as E
import Task as T
import TaskPort as TP
import WebSocket as WS


type alias Camera =
    { ws : WS.WebSocket, name : String }


type alias OpenCameraJson =
    { name : String }


encodeOpenCameraJson : OpenCameraJson -> E.Value
encodeOpenCameraJson packet =
    E.object
        [ ( "OpenCamera", E.object [ ( "name", E.string packet.name ) ] )
        ]


openCameraQuery name ws =
    WS.sendWebSocket ws (encodeOpenCameraJson { name = name })


open : String -> T.Task TP.Error Camera
open name =
    WS.open "ws://localhost:8000/ws"
        |> T.map
            (\ws ->
                let
                    _ =
                        openCameraQuery name ws
                in
                ws
            )
            (const openCameraQuery)
        |> T.map (\ws -> Camera ws name)



-- |> T.map (\ws -> Camera ws name)
