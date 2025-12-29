// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod camera {
    tonic::include_proto!("camera");
}
use camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    GetCameraListRequest, GetCameraListResponse,
};

use std::sync::mpsc;
use std::thread;

use tauri::Event;
use tauri::{webview::PageLoadEvent, AppHandle, Emitter, Listener, Manager};
use tauri_plugin_log::{Target, TargetKind};

use tokio::sync::Mutex;
use tonic::transport::Server;
use tonic::{Request, Response, Status};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

use less_i_cam_lib::python_ffi::enumerate_cameras;

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
use tonic::service::LayerExt;

// webviewが読み込むリソース
// https://v2.tauri.app/ja/reference/config/
// tauri.conf.jsonのfrontendDistが読み込まれ、エントリポイントにはディレクトリ内に存在するindex.htmlが検索され指定される
// いやviteの開発サーバーから取得されてるっぽい？
// https://v2.tauri.app/ja/develop/

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

            // .into_inner();
            // .named_layer(CameraServiceServer::new(greeter));

            Server::builder()
                .accept_http1(true)
                .layer(allow_cors)
                .layer(GrpcWebLayer::new())
                // .add_service(greeter)
                .add_service(CameraServiceServer::new(camera_service))
                // .add_service(greeter)
                .serve(addr)
                .await
                .unwrap();
        });
    });

    launch_tauri_app();
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn launch_tauri_app() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        // .plugin(
        //     tauri_plugin_log::Builder::new()
        //         .targets([
        //             Target::new(TargetKind::Stdout),
        //             Target::new(TargetKind::LogDir { file_name: None }),
        //             Target::new(TargetKind::Webview),
        //         ])
        //         .build(),
        // )
        .invoke_handler(tauri::generate_handler![])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
