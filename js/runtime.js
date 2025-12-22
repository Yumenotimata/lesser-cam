class Runtime {
    constructor() {
        this.webSockets = new Map();
        this.uuid = 0;
    }

    async openWebSocket(url) {
        let ws = await new WebSocketWrapper(url);
        let uuid = this.uuid++;
        this.webSockets.set(uuid, ws);
        return { uuid: uuid };
    }

    async sendWebSocket(uuid, message) {
        console.log("Runtime:sendWebSocket uuid", uuid);
        console.log("Runtime:sendWebSocket message", message);
        await this.webSockets.get(uuid).send(message);
    }

    async callWebSocket(uuid, message) {
        console.log("Runtime:callWebSocket uuid", uuid);
        console.log("Runtime:callWebSocket message", message);
        let res = await this.webSockets.get(uuid).call(message);
        console.log("Runtime:callWebSocket res", res);
        return res;
    }
}