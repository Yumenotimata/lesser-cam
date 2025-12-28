// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
mod camera {
    tonic::include_proto!("camera");
}
use std::thread;
use tauri::{Manager, Window};
use tauri_elm_app::enumerate_cameras;
use tokio::time::sleep;
use tonic::transport::Server;
use tonic::{Request, Response, Status};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

use camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    GetCameraListRequest, GetCameraListResponse,
};
use webrtc::api::APIBuilder;
use webrtc::peer_connection::configuration::RTCConfiguration;

struct MyCameraService {}

impl MyCameraService {
    fn new() -> Self {
        Self {}
    }
}

#[tonic::async_trait]
impl CameraService for MyCameraService {
    async fn get_camera_list(
        &self,
        _request: Request<GetCameraListRequest>,
    ) -> Result<Response<GetCameraListResponse>, Status> {
        Ok(Response::new(GetCameraListResponse {
            camera_list: enumerate_cameras()
                .unwrap()
                .into_iter()
                .map(|(_, name)| name)
                .collect(),
        }))
    }
}

fn main() {
    thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let addr = "127.0.0.1:50051".parse().unwrap();
            let camera_service = MyCameraService::new();

            // gRPC-web対応
            let allow_cors = CorsLayer::new()
                .allow_origin(tower_http::cors::Any)
                .allow_headers(tower_http::cors::Any)
                .allow_methods(tower_http::cors::Any);

            Server::builder()
                .accept_http1(true)
                .layer(allow_cors)
                .layer(GrpcWebLayer::new())
                .add_service(CameraServiceServer::new(camera_service))
                .serve(addr)
                .await
                .unwrap();
        });
    });

    launch_webrtc();

    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![emit_sdp_offer])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn emit_sdp_offer(desc: String) {
    println!(
        "--------------------------------------------offer: {}",
        desc
    );
}

fn launch_webrtc() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        println!("here");
        // localhost内での通信のため、STUNサーバーは使用しない
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

        let desc = serde_json::json!({
            "type": offer.sdp_type,
            "sdp": offer.sdp,
        });

        println!("offer: {}", desc);
        // window.emit("sdp-offer", desc).unwrap();
    });
}
