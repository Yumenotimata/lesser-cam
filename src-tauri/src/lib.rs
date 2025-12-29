use std::sync::mpsc;

use tauri::Event;
use tauri::{webview::PageLoadEvent, AppHandle, Emitter, Listener, Manager};
use tauri_plugin_log::{Target, TargetKind};

use webrtc::api::APIBuilder;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(
            tauri_plugin_log::Builder::new()
                .targets([
                    Target::new(TargetKind::Stdout),
                    Target::new(TargetKind::LogDir { file_name: None }),
                    Target::new(TargetKind::Webview),
                ])
                .build(),
        )
        .invoke_handler(tauri::generate_handler![tauri_ready])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
async fn tauri_ready(app: AppHandle) {
    println!("tauri ready");
    let config = RTCConfiguration {
        ..Default::default()
    };

    let api = APIBuilder::new().build();
    let peer_connection = api.new_peer_connection(config).await.unwrap();

    let offer = peer_connection.create_offer(None).await.unwrap();
    peer_connection
        .set_local_description(offer.clone())
        .await
        .unwrap();

    // peer_connection.on_ice_candidate(Box::new(move |candidate| Box::pin(async move {})));

    let desc = serde_json::json!({
        "type": offer.sdp_type,
        "sdp": offer.sdp,
    });

    app.emit("sdp-offer", desc).unwrap();

    let (tx, rx) = mpsc::channel();

    app.once("sdp-answer", move |event: Event| {
        tx.send(event.payload().to_owned()).unwrap()
    });

    let sdp = rx.recv().unwrap();
    let desc = serde_json::from_str::<RTCSessionDescription>(&sdp).unwrap();
    peer_connection.set_remote_description(desc).await.unwrap();
}
