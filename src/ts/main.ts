import { Client, createClient } from "@connectrpc/connect";
import { createConnectTransport, createGrpcWebTransport } from "@connectrpc/connect-web";
import { CameraService, GetLatestCameraFrameResponse } from "./camera_pb";
import { trace, info, error, attachConsole } from '@tauri-apps/plugin-log'
const detach = await attachConsole()

// setTimeout(async () => {

//     const transport = createGrpcWebTransport({
//         baseUrl: "http://localhost:50051",
//     });

//     const client = createClient(CameraService, transport);

//     info("here");
//     info("camera list: " + await client.getCameraList({}));
// }, 1000);



customElements.define("elm-canvas", class extends HTMLElement {

    private canvas!: HTMLCanvasElement;
    private div!: HTMLDivElement;
    private ctx!: CanvasRenderingContext2D;
    private rpcClient!: Client<typeof CameraService>;
    private _cameraName!: string;
    private _rpcUrl!: string;

    static observedAttributes = ["cameraname", "rpcurl"];

    constructor() {
        super();
    }

    connectedCallback() {
        // trace("connectedCallback");

        this.canvas = this.querySelector("canvas")!;
        this.div = this.querySelector("div")!;

        this.canvas.width = this.div.clientWidth;
        this.canvas.height = this.div.clientHeight;

        this.ctx = this.canvas.getContext("2d")!;

        const loop = () => {
            this.render();
            requestAnimationFrame(loop);
        }

        const resizeObserver = new ResizeObserver(() => {
            this.canvas.width = this.div.clientWidth;
            this.canvas.height = this.div.clientHeight;
        });

        resizeObserver.observe(this.div);

        loop();
    }

    // attributeChangedCallback(name: string, oldValue: string, newValue: string) {
    //     info("attributeChangedCallback");

    //     if (name === "cameraname") {
    //         this.cameraName = newValue;
    //     }

    //     if (name === "rpcurl") {
    //         this.rpcUrl = newValue;
    //         const transport = createGrpcWebTransport({
    //             baseUrl: this.rpcUrl,
    //         });
    //         this.rpcClient = createClient(CameraService, transport);
    //     }
    // }

    set rpcUrl(rpcUrl: string) {
        info("set rpcUrl" + rpcUrl);
        const transport = createGrpcWebTransport({
            baseUrl: rpcUrl,
        });
        this.rpcClient = createClient(CameraService, transport);
    }

    set cameraName(cameraName: string) {
        info("set cameraName" + cameraName);
        this._cameraName = cameraName;
        this.requestId++;
    }

    private inFlight = false;
    private requestId = 0;

    async render() {
        if (!this.rpcClient || !this._cameraName) return;
        if (this.inFlight) return;

        const currentId = ++this.requestId;
        this.inFlight = true;

        try {
            const response = await this.rpcClient.getLatestCameraFrame({
                cameraName: this._cameraName,
            });

            // cameraName が変わっていたら捨てる
            if (currentId !== this.requestId) return;

            this.draw(response.frame);
        } finally {
            this.inFlight = false;
        }
    }

    private draw(buffer: Uint8Array) {
        const frame = new Uint8Array(buffer);
        const blob = new Blob([frame], { type: "image/jpeg" });
        const url = URL.createObjectURL(blob);
        const img = new Image();
        img.onload = () => {
            const canvasW = this.canvas.width;
            const canvasH = this.canvas.height;

            // アスペクト比を維持して最大化
            const imgRatio = img.width / img.height;
            let w = canvasW;
            let h = canvasW / imgRatio;

            if (h > canvasH) {
                h = canvasH;
                w = canvasH * imgRatio;
            }

            // canvas 内で中央に配置
            const x = (canvasW - w) / 2;
            const y = (canvasH - h) / 2;

            this.ctx.drawImage(img, x, y, w, h);
            URL.revokeObjectURL(url);
        };
        img.src = url;
    }


    // render() {
    //     // info("render");
    //     if (!this.rpcClient || !this._cameraName) return;
    //     // info("rpcClient: " + this.rpcClient);
    //     // info("cameraName: " + this.cameraName);

    //     this.rpcClient.getLatestCameraFrame({ cameraName: this._cameraName }).then((response) => {
    //         const frame = new Uint8Array(response.frame);
    //         const blob = new Blob([frame], { type: "image/jpeg" });
    //         const url = URL.createObjectURL(blob);
    //         const img = new Image();
    //         img.onload = () => {
    //             const canvasW = this.canvas.width;
    //             const canvasH = this.canvas.height;

    //             // アスペクト比を維持して最大化
    //             const imgRatio = img.width / img.height;
    //             let w = canvasW;
    //             let h = canvasW / imgRatio;

    //             if (h > canvasH) {
    //                 h = canvasH;
    //                 w = canvasH * imgRatio;
    //             }

    //             // canvas 内で中央に配置
    //             const x = (canvasW - w) / 2;
    //             const y = (canvasH - h) / 2;

    //             this.ctx.drawImage(img, x, y, w, h);
    //             URL.revokeObjectURL(url);
    //         };
    //         img.src = url;
    //     });
    // }
})
