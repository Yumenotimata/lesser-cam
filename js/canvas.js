customElements.define("elm-canvas", class extends HTMLElement {
    constructor() {
        super();
        this.initialized = false;
    }

    connectedCallback() {
        // this.div = document.createElement('div');
        // this.appendChild(this.div);
        // this.canvas = document.createElement('canvas');
        // this.canvas.width = 1920;
        // this.canvas.height = 1080;
        // this.canvas.width = 1920;
        // this.canvas.height = 1080;
        // this.appendChild(this.canvas);
        // this.div.appendChild(this.canvas);
        this.canvas = this.querySelector("canvas");
        this.div = this.querySelector("div");

        this.canvas.width = this.div.clientWidth;
        this.canvas.height = this.div.clientHeight;

        this.ctx = this.canvas.getContext("2d");
        this.initialized = true;

        const loop = () => {
            setTimeout(() => {
                this.render();
                requestAnimationFrame(loop);
                // console.log(this.div.clientWidth, this.div.clientHeight);
            }, 1000 / 60);
        }

        const resizeObserver = new ResizeObserver(() => {
            this.canvas.width = this.div.clientWidth;
            this.canvas.height = this.div.clientHeight;
        });

        resizeObserver.observe(this.div);

        loop();
    }

    static get observedAttributes() {
        return ["width", "height"];
    }

    attributeChangedCallback(name, oldValue, newValue) {
        // if (name === "width") {
        //     this.canvas.width = parseInt(newValue);
        // } else if (name === "height") {
        //     this.canvas.height = parseInt(newValue);
        // }
    }

    set bytes(value) {
        this.value = value;
    }

    render() {
        if (!this.initialized) return;

        const binary = new Uint8Array(this.value);
        const blob = new Blob([binary], { type: "image/jpeg" });
        const url = URL.createObjectURL(blob);
        const img = new Image();
        img.onload = () => {
            // this.canvas.width = img.width / 2;
            // this.canvas.height = img.height / 2;
            // if (this.canvas.width !== img.width || this.canvas.height !== img.height) {
            //     this.canvas.width = img.width;
            //     this.canvas.height = img.height;
            // }

            // this.ctx.drawImage(img, 0, 0);
            // URL.revokeObjectURL(url);
            // const ratio = Math.min(this.canvas.width / img.width, this.canvas.height / img.height);
            const w = this.canvas.width;
            const h = this.canvas.width * img.height / img.width;
            this.ctx.drawImage(img, 0, 0, w, h);
            URL.revokeObjectURL(url);
            // console.log('render');
        };
        img.src = url;
    }
})