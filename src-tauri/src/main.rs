// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod camera {
    tonic::include_proto!("camera");
}
use camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    GetCameraListRequest, GetCameraListResponse, GetLatestCameraFrameRequest,
    GetLatestCameraFrameResponse,
};
use opencv::{core::Vector, imgcodecs};

use std::{sync::mpsc, thread::sleep};
use std::{sync::Arc, thread, time::Duration};

use tauri::Event;
use tauri::{webview::PageLoadEvent, AppHandle, Emitter, Listener, Manager};
use tauri_plugin_log::{Target, TargetKind};

use tokio::sync::Mutex;
use tonic::transport::Server;
use tonic::{Request, Response, Status};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

use less_i_cam_lib::{python_ffi::enumerate_cameras, Camera};
use ws::{connect, CloseCode};

struct MyCameraServiceState {
    camera: Camera,
}

struct MyCameraService {
    stream_thread: Option<thread::JoinHandle<()>>,
    state: Arc<Mutex<MyCameraServiceState>>,
}

impl MyCameraService {
    fn new() -> Self {
        Self {
            stream_thread: None,
            state: Arc::new(Mutex::new(MyCameraServiceState {
                camera: Camera::new(0).unwrap(),
            })),
        }
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

    async fn get_latest_camera_frame(
        &self,
        request: Request<GetLatestCameraFrameRequest>,
    ) -> Result<Response<GetLatestCameraFrameResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        let target_camera_id = enumerate_cameras()
            .unwrap()
            .into_iter()
            .find(|(_, name)| *name == target_camera_name)
            .map(|(id, _)| id);

        let target_camera_id = Some("test".to_owned());

        // let frame = Camera::new(0).unwrap().read().unwrap();
        let frame = self.state.lock().await.camera.read().unwrap();

        let mut frame_vec = Vector::new();
        imgcodecs::imencode_def(".jpeg", &frame, &mut frame_vec).unwrap();
        let frame_vec: Vec<u8> = frame_vec.into_iter().collect();

        Ok(Response::new(GetLatestCameraFrameResponse {
            frame: frame_vec,
        }))
        // if let Some(target_camera_id) = target_camera_id {
        //     let camera = Camera::new(target_camera_id).unwrap();
        //     let frame = camera.read().unwrap();
        //     Ok(Response::new(GetLatestCameraFrameResponse { frame }))
        // } else {
        //     Err(Status::not_found("camera not found"))
        // }
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

    sleep(Duration::from_secs(1));

    launch_tauri_app();
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn launch_tauri_app() {
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
        .invoke_handler(tauri::generate_handler![])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
