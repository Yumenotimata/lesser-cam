import { Client, createClient } from "@connectrpc/connect";
import { createConnectTransport, createGrpcWebTransport } from "@connectrpc/connect-web";
import { CameraService } from "./camera_pb";
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
    private cameraName!: string;
    // private rpcUrl!: string;

    constructor() {
        super();
    }

    connectedCallback() {
        this.canvas = this.querySelector("canvas")!;
        this.div = this.querySelector("div")!;

        this.canvas.width = this.div.clientWidth;
        this.canvas.height = this.div.clientHeight;

        this.ctx = this.canvas.getContext("2d")!;

        const loop = () => {
            setTimeout(() => {
                this.render();
                requestAnimationFrame(loop);
            }, 1000 / 60);
        }

        const resizeObserver = new ResizeObserver(() => {
            this.canvas.width = this.div.clientWidth;
            this.canvas.height = this.div.clientHeight;
        });

        resizeObserver.observe(this.div);

        loop();
    }

    // なぜか動作しない人たち
    // static get observedAttributes() {
    //     return ["cameraName", "rpcUrl"];
    // }

    // attributeChangedCallback() {

    // }

    set rpcUrl(rpcUrl: string) {
        info("set rpcUrl" + rpcUrl);
        const transport = createGrpcWebTransport({
            baseUrl: rpcUrl,
        });
        this.rpcClient = createClient(CameraService, transport);
    }

    render() {
        if (!this.rpcClient || !this.cameraName) return;

        this.rpcClient.getLatestCameraFrame({ cameraName: this.cameraName }).then((response) => {
            const frame = new Uint8Array(response.frame);
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
        });
    }
})