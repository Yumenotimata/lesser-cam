class Runtime {
    constructor() {
        this.webSockets = new Map();
    }

    async openWebSocket(url) {
        let ws = await new WebSocketWrapper(url);
        let uuid = crypto.randomUUID();
        this.webSockets.set(uuid, ws);
        return { uuid: uuid };
    }

    async sendWebSocket(uuid, message) {
        console.log("Runtime:sendWebSocket uuid", uuid);
        console.log("Runtime:sendWebSocket message", message);
        await this.webSockets.get(uuid).send(JSON.stringify(message));
    }
}