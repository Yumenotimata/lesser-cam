module WebSocket exposing (..)

import Json.Decode as D
import Json.Encode as E
import Task as T
import TaskPort as TP


type alias WebSocket =
    { uuid : Int
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
    { uuid : Int
    , message : E.Value
    }


encodeSendWebSocketJson : SendWebSocketJson -> E.Value
encodeSendWebSocketJson packet =
    E.object
        [ ( "uuid", E.int packet.uuid )
        , ( "message", packet.message )
        ]


decodeSendWebSocketJson : D.Decoder SendWebSocketJson
decodeSendWebSocketJson =
    D.map2 SendWebSocketJson
        (D.field "uuid" D.int)
        (D.field "message" D.value)


sendWebSocket : WebSocket -> E.Value -> T.Task TP.Error SendWebSocketJson
sendWebSocket ws message =
    TP.call
        { function = "sendWebSocket"
        , argsEncoder = encodeSendWebSocketJson
        , valueDecoder = decodeSendWebSocketJson
        }
        { uuid = ws.uuid, message = message }


decode : D.Decoder WebSocket
decode =
    D.map WebSocket (D.field "uuid" D.int)


encode : WebSocket -> E.Value
encode socket =
    E.object
        [ ( "uuid", E.int socket.uuid ) ]
