// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod camera {
    tonic::include_proto!("camera");
}

use std::thread;

use tonic::transport::Server;
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;
use vmask_lib::PyVirtualCam;

use crate::camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    TestRequest, TestResponse,
};

struct MyCameraService;

impl MyCameraService {
    fn new() -> MyCameraService {
        MyCameraService
    }
}

#[tonic::async_trait]
impl CameraService for MyCameraService {
    async fn test(
        &self,
        _request: tonic::Request<TestRequest>,
    ) -> Result<tonic::Response<TestResponse>, tonic::Status> {
        thread::spawn(|| {
            let pyvirtualcam = PyVirtualCam::new(320, 240, 20).unwrap();

            let mut c: u32 = 0;
            loop {
                pyvirtualcam.send(vec![(c % 255) as u8; 320 * 240 * 3]);
                c += 1;
            }
        });

        Ok(tonic::Response::new(TestResponse {}))
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

    tauri_launch();
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn tauri_launch() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
