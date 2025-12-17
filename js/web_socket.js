class WebSocketWrapper {
    constructor(url) {
        this.socket = new WebSocket(url);
        this.messagePool = {};
        this.isOpen = false;

        this.socket.addEventListener("open", (event) => {
            this.isOpen = true;
        });

        this.socket.addEventListener("message", (event) => {
            let data = JSON.parse(event.data);
            if (data.uuid in this.messagePool) {
                this.messagePool[data.uuid](event);
                delete this.messagePool[data.uuid];
            }
        });

        return new Promise((resolve, reject) => {
            let intervalId = setInterval(() => {
                if (this.isOpen) {
                    resolve(this);
                    clearInterval(intervalId);
                }
            }, 10);
        });
    }

    async send(message) {
        this.socket.send(message);
    }

    async call(message) {
        let uuid = crypto.randomUUID();
        this.socket.send(
            JSON.stringify(
                Object.assign(
                    { message: message },
                    { uuid: uuid }
                )
            )
        );

        return new Promise((resolve, reject) => {
            this.messagePool[uuid] = (recv) => {
                resolve(JSON.parse(recv.data));
            }
        });
    }
}