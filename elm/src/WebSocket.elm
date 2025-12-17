module WebSocket exposing (..)

import Json.Decode as D
import Json.Encode as E
import Task as T
import TaskPort as TP


type alias WebSocket =
    { uuid : String
    }


type alias OpenWebSocketJson =
    { url : String
    }


encodeOpenWebSocketJson packet =
    E.object
        [ ( "url", E.string packet.url ) ]


open : String -> T.Task TP.Error WebSocket
open url =
    let
        ws =
            TP.call
                { function = "openWebSocket"
                , argsEncoder = encodeOpenWebSocketJson
                , valueDecoder = decode
                }
                { url = url }
    in
    ws


callWebSocket ws message =
    TP.call
        { function = "callWebSocket"
        , argsEncoder = encode
        , valueDecoder = D.string
        }


type alias SendWebSocketJson =
    { uuid : String
    , message : E.Value
    }


encodeSendWebSocketJson : SendWebSocketJson -> E.Value
encodeSendWebSocketJson packet =
    E.object
        [ ( "uuid", E.string packet.uuid )
        , ( "message", packet.message )
        ]


sendWebSocket : WebSocket -> E.Value -> T.Task TP.Error String
sendWebSocket ws message =
    TP.call
        { function = "sendWebSocket"
        , argsEncoder = encodeSendWebSocketJson
        , valueDecoder = D.string
        }
        { uuid = ws.uuid, message = message }


decode : D.Decoder WebSocket
decode =
    D.map WebSocket (D.field "uuid" D.string)


encode : WebSocket -> E.Value
encode socket =
    E.object
        [ ( "uuid", E.string socket.uuid ) ]
