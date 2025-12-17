// let runtime = new Runtime();

// TaskPort.install();

// Elmからの引数argsはjson
// 型情報はelm/src/WebSocket.elmで定義

// TaskPort.register("openWebSocket", async (args) => {
//     console.log("TaskPort:openWebSocket url", args.url);
//     return runtime.openWebSocket(args.url);
// });

// TaskPort.register("sendWebSocket", async (args) => {
//     console.log("TaskPort:sendWebSocket uuid", args.uuid);
//     console.log("TaskPort:sendWebSocket message", args.message);
//     await runtime.sendWebSocket(args.uuid, args.message);
//     return "dummy";
// });

var app = Elm.Main.init({ node: document.getElementById('app') });