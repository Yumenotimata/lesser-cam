import { invoke } from "@tauri-apps/api/core";
import { listen, emit } from '@tauri-apps/api/event';
import { trace, info, error, attachConsole } from '@tauri-apps/plugin-log'

const detach = await attachConsole()

await listen<{ type: RTCSdpType; sdp: string }>("sdp-offer", (event) => {
  trace("sdp-offer: " + JSON.stringify(event.payload));
  const desc: RTCSessionDescriptionInit = new RTCSessionDescription(event.payload);

  const receiverConnection = new RTCPeerConnection();
  trace("receiverConnection created");

  receiverConnection.setRemoteDescription(desc)
    .then(() => {
      trace("setRemoteDescription");
      return receiverConnection.createAnswer();
    })
    .then((answer) => {
      trace("setLocalDescription");
      return receiverConnection.setLocalDescription(answer);
    })
    .then(() => {
      trace("emit sdp-answer: " + JSON.stringify({ type: receiverConnection.localDescription?.type, sdp: receiverConnection.localDescription?.sdp }));
      emit("sdp-answer", { type: receiverConnection.localDescription?.type, sdp: receiverConnection.localDescription?.sdp });
    });
});

await invoke("tauri_ready", {});