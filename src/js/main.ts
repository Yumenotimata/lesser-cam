import { invoke } from "@tauri-apps/api/core";

window.addEventListener("DOMContentLoaded", () => {
  invoke("emit_sdp_offer", { desc: "offer" });
});