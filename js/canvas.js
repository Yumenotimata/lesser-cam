customElements.define("elm-canvas", class extends HTMLElement {
    constructor() {
        super();
        this.initialized = false;
    }

    connectedCallback() {
        this.canvas = document.createElement('canvas');
        this.canvas.width = 1920;
        this.canvas.height = 1080;
        // this.canvas.width = 1920;
        // this.canvas.height = 1080;
        this.appendChild(this.canvas);
        this.ctx = this.canvas.getContext("2d");
        this.initialized = true;

        const loop = () => {
            setTimeout(() => {
                requestAnimationFrame(loop);
                this.render();
            }, 10);
        }

        loop();
    }

    // static get observedAttributes() {
    // return ["bytes"]
    // }

    set bytes(value) {
        console.log(value);
        this.value = value;
        // this.render();
    }

    render() {
        if (!this.initialized) return;

        // const imageData = this.ctx.createImageData(this.canvas.width, this.canvas.height);
        // imageData.data.set(this.value);
        // this.ctx.putImageData(imageData, 0, 0);
        // if (this.value)
        // const pixels = new Uint8Array(this.value);
        // if (pixels.length < 100) return;
        // const imageData = this.ctx.createImageData(this.canvas.width, this.canvas.height);
        // for (let i = 0; i < this.value.length; i++) {
        //     imageData.data[i] = this.value[i];
        // }
        // for (let i = 0; i < imageData.data.length; i += 4) {
        //     // ピクセルデータを書き換える
        //     // imageData.data[i + 0] = 190; // R 値
        //     // imageData.data[i + 1] = 0; // G 値
        //     // imageData.data[i + 2] = 210; // B 値
        //     // imageData.data[i + 3] = 255; // A 値
        //     imageData.data[i + 0] = this.value[i];
        //     imageData.data[i + 1] = this.value[i + 1];
        //     imageData.data[i + 2] = this.value[i + 2];
        //     imageData.data[i + 3] = 255;
        // }
        // for (let i = 0; i < this.value.length; i += 4) {
        //     imageData.data[i] = this.value[i];
        //     imageData.data[i + 1] = this.value[i + 1];
        //     imageData.data[i + 2] = this.value[i + 2];
        //     imageData.data[i + 3] = 255;
        // }
        const w = this.canvas.width;
        const h = this.canvas.height;
        const rgba = new Uint8ClampedArray(w * h * 4);

        for (let i = 0, j = 0; i < this.value.length; i += 3, j += 4) {
            rgba[j] = this.value[i];     // R
            rgba[j + 1] = this.value[i + 1]; // G
            rgba[j + 2] = this.value[i + 2]; // B
            rgba[j + 3] = 255;               // A
        }

        const img = new ImageData(rgba, w, h);
        this.ctx.putImageData(img, 0, 0);
        // const pixels = new Uint8ClampedArray(this.value);
        // const imageData = new ImageData(pixels, w, h);
        // this.ctx.putImageData(imageData, 0, 0);

        console.log('render');

        // console.log(this.value.length);
        // imageData.src = 'data:image/bmp;base64,' + btoa(this.value);
        // // iamgeData.data.set(pixels);
        // this.ctx.putImageData(imageData, 0, 0);
        // this.ctx.putImageData(imageData, 0, 0);
        // console.log(imageData);
        // this.ctx.drawImage(imageData, 0, 0);
        // const blob = new Blob([this.value], { type: "image/bmp" });
        // const url = URL.createObjectURL(blob);

        // const img = new Image();
        // img.onload = () => {
        //     this.ctx.drawImage(img, 0, 0);
        //     URL.revokeObjectURL(url);
        // };
        // img.src = url;
    }
})