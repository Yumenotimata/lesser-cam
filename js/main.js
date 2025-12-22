let runtime = new Runtime();

TaskPort.install();

// Elmからの引数argsはjson
// 型情報はelm/src/WebSocket.elmで定義

TaskPort.register("openWebSocket", async (args) => {
    console.log("TaskPort:openWebSocket url", args.url);
    return await runtime.openWebSocket(args.url);
});

TaskPort.register("sendWebSocket", async (args) => {
    console.log("TaskPort:sendWebSocket uuid", args.uuid);
    console.log("TaskPort:sendWebSocket message", args.message);
    let res = await runtime.callWebSocket(args.uuid, args.message);
    console.log("TaskPort:sendWebSocket res", res);
    return res;
});

var app = Elm.Main.init({ node: document.getElementById('app') });