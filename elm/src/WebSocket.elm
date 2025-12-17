module WebSocket exposing (..)

import Json.Decode as D
import Json.Encode as E
import Task as T
import TaskPort as TP


type alias WebSocket =
    { uuid : String
    }


openWebSocket : String -> T.Task TP.Error WebSocket
openWebSocket url =
    let
        ws =
            TP.call
                { function = "openWebSocket"
                , argsEncoder = E.string
                , valueDecoder = decode
                }
                url
    in
    ws


callWebSocket ws message =
    TP.call
        { function = "callWebSocket"
        , argsEncoder = encode
        , valueDecoder = D.string
        }


decode : D.Decoder WebSocket
decode =
    D.map WebSocket (D.field "uuid" D.string)


encode : WebSocket -> E.Value
encode socket =
    E.object
        [ ( "uuid", E.string socket.uuid ) ]
