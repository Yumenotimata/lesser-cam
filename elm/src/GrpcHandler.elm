module GrpcHandler exposing (..)

import Grpc as G


type alias GrpcHandler =
    { host : String
    }


new host =
    { host = host }


send grpcHandler rpc request =
    G.new rpc request
        |> G.setHost grpcHandler.host
        |> G.toTask
