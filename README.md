# lesser-cam

## Elm gRPC Code Generation from .proto
- .protoからelmコードの生成は[protoc-gen-elm](shttps://www.npmjs.com/package/protoc-gen-elm)を使用
- protoc-gen-elmはElmパッケージの[elm-protocol-buffers](https://package.elm-lang.org/packages/eriktim/elm-protocol-buffers/1.2.0), [elm-grpc](https://package.elm-lang.org/packages/anmolitor/elm-grpc/latest/)を使用したコードを生成

## gRPC Server
- elmを動作させるWebView(というかChromium?)はgRPCが使用するHTTP/2をサポートしていないため、rust側でHTTP/2をHTTP/1に変換するプロキシサーバー(tonic-web)を使用
- tonic-webのわかりやすいサンプルソースがかなりバージョンセンシティブなので、このプロジェクトの構成を再利用する際はCargo.tomlを丸コピすることを強く推奨