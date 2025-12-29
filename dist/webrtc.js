// src/js/webrtc.js
var { invoke } = window.__TAURI__.tauri;
setInterval(() => {
  app.ports.testReceiver.send("ff" + JSON.stringify(window.__TAURI__));
}, 1000);
