import { listen } from '@tauri-apps/api/event';
import { invoke } from "@tauri-apps/api/core";

// listen('sdp-offer', (event) => {

// });
setInterval(() => {
    app.ports.testReceiver.send("ff" + JSON.stringify(window.__TAURI_INTERNALS__));
}, 1000);


// invoke("emit_sdp_offer", { desc: "offer" });

// const receiverConnection = new RTCPeerConnection();

// const offer = window.prompt("offer");

// receiverConnection
//     .setRemoteDescription(JSON.parse(offer))
//     .then(() => {
//         return receiverConnection.createAnswer();
//     })
//     .then((answer) => {
//         receiverConnection.setLocalDescription(answer);
//         return answer;
//     })
//     .then((answer) => {
//         window.prompt("answer", JSON.stringify(answer));
//     });