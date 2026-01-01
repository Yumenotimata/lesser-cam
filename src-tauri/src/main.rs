// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod camera {
    tonic::include_proto!("camera");
}
use camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    GetCameraListRequest, GetCameraListResponse, GetLatestCameraFrameRequest,
    GetLatestCameraFrameResponse, GetLatestVirtualCameraFrameRequest,
    GetLatestVirtualCameraFrameResponse, PublishVirtualCameraRequest, PublishVirtualCameraResponse,
    UnpublishVirtualCameraRequest, UnpublishVirtualCameraResponse,
};
use opencv::core::{Mat, MatTraitConstManual};
use opencv::prelude::VideoCaptureTrait;
use opencv::videoio::VideoCapture;
use opencv::{core::Vector, imgcodecs, imgproc};

use rustc_hash::FxHasher;
use std::{collections::HashMap, hash::BuildHasherDefault, time::Instant};
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

use less_i_cam_lib::{python_ffi::enumerate_cameras, Camera, PyVirtualCam};
use ws::{connect, CloseCode};

use crate::camera::CameraId;

#[derive(Debug, Clone)]
struct VirtualCameraConfig {
    // 0.0 ~ 1.0
    pub resolution_ratio: f32,
}

impl Default for VirtualCameraConfig {
    fn default() -> Self {
        Self {
            resolution_ratio: 1.0,
        }
    }
}

type VirtualCameraId = String;

struct CameraContainer {
    id: CameraId,
    camera: Camera,
    virtual_camera_config: VirtualCameraConfig,
}

struct MyCameraServiceState {
    camera_containers: HashMap<CameraId, CameraContainer>,
    virtual_camera_stream: Option<(CameraId, thread::JoinHandle<()>)>,
}

impl MyCameraServiceState {
    fn new() -> Self {
        Self {
            camera_containers: HashMap::new(),
            virtual_camera_stream: None,
        }
    }

    fn get_camera(&mut self, target: CameraId) -> Camera {
        let target_clone = target.clone();

        self.camera_containers
            .entry(target.clone())
            .or_insert_with(move || CameraContainer {
                id: target.clone(),
                camera: Camera::new(target.id).unwrap(),
                virtual_camera_config: VirtualCameraConfig::default(),
            });

        self.camera_containers
            .get(&target_clone)
            .unwrap()
            .camera
            .clone()
    }
}

struct MyCameraService {
    state: Arc<Mutex<MyCameraServiceState>>,
    frame_sender: crossbeam_channel::Sender<Vec<u8>>,
}

impl MyCameraService {
    fn new(frame_sender: crossbeam_channel::Sender<Vec<u8>>) -> Self {
        Self {
            state: Arc::new(Mutex::new(MyCameraServiceState::new())),
            frame_sender,
        }
    }
}
fn clamp<T: PartialOrd>(value: T, min: T, max: T) -> T {
    if value < min {
        min
    } else if value > max {
        max
    } else {
        value
    }
}

#[tonic::async_trait]
impl CameraService for MyCameraService {
    async fn get_camera_list(
        &self,
        _request: Request<GetCameraListRequest>,
    ) -> Result<Response<GetCameraListResponse>, Status> {
        let camera_list: Vec<CameraId> = enumerate_cameras()
            .unwrap()
            .into_iter()
            .map(|(id, name)| CameraId { id, name })
            .collect();

        Ok(Response::new(GetCameraListResponse { camera_list }))
    }

    async fn get_latest_camera_frame(
        &self,
        request: Request<GetLatestCameraFrameRequest>,
    ) -> Result<Response<GetLatestCameraFrameResponse>, Status> {
        let target_camera_id = request.get_ref().camera_id.clone().unwrap();
        let mut state = self.state.lock().await;
        let mut camera = state.get_camera(target_camera_id);

        let mat = camera.read().unwrap();

        let mut frame = Vector::new();
        imgcodecs::imencode_def(".jpeg", &mat, &mut frame).unwrap();

        let frame: Vec<u8> = frame.into_iter().collect();

        Ok(Response::new(GetLatestCameraFrameResponse { frame }))
    }

    async fn get_latest_virtual_camera_frame(
        &self,
        request: Request<GetLatestVirtualCameraFrameRequest>,
    ) -> Result<Response<GetLatestVirtualCameraFrameResponse>, Status> {
        let target_camera_id = request.get_ref().camera_id.clone().unwrap();
        let virtual_camera_config = request.get_ref().config.clone().unwrap();

        let mut state = self.state.lock().await;
        let mut camera = state.get_camera(target_camera_id);

        let mat = camera.read().unwrap();

        let mut resized = Mat::default();

        let scale = clamp(virtual_camera_config.resolution_ratio, 0.0, 1.0) as f64;

        imgproc::resize(
            &mat,
            &mut resized,
            opencv::core::Size::default(),
            scale,
            scale,
            imgproc::INTER_AREA,
        )
        .unwrap();

        let mut frame = Vector::new();
        imgcodecs::imencode_def(".jpeg", &resized, &mut frame).unwrap();

        let frame: Vec<u8> = frame.into_iter().collect();

        Ok(Response::new(GetLatestVirtualCameraFrameResponse { frame }))
    }

    async fn publish_virtual_camera(
        &self,
        request: Request<PublishVirtualCameraRequest>,
    ) -> Result<Response<PublishVirtualCameraResponse>, Status> {
        let target_camera_id = request.get_ref().camera_id.clone().unwrap();
        let virtual_camera_config = request.get_ref().config.clone().unwrap();

        let mut state = self.state.lock().await;

        if state
            .virtual_camera_stream
            .as_ref()
            .map(|(id, _)| *id == target_camera_id)
            .unwrap_or(false)
        {
            return Ok(Response::new(PublishVirtualCameraResponse {}));
        } else {
            let camera = state.get_camera(target_camera_id.clone());

            let mut camera_clone = camera.clone();

            let frame_sender = self.frame_sender.clone();

            let new_stream = thread::spawn(move || {
                loop {
                    let mat = camera_clone.read().unwrap();
                    // let mut resized = Mat::default();

                    // let scale = clamp(config.resolution_ratio, 0.0, 1.0) as f64;

                    // imgproc::resize(
                    //     &mat,
                    //     &mut resized,
                    //     opencv::core::Size::default(),
                    //     1.0,
                    //     1.0,
                    //     imgproc::INTER_AREA,
                    // )
                    // .unwrap();let mut frame = Mat::default();
                    // let mut frame = Mat::default();
                    let frame = mat.data_bytes().unwrap().to_vec();

                    frame_sender.send(frame).unwrap();
                }
            });
            state.virtual_camera_stream = Some((target_camera_id, new_stream));

            Ok(Response::new(PublishVirtualCameraResponse {}))
        }
    }

    async fn unpublish_virtual_camera(
        &self,
        request: Request<UnpublishVirtualCameraRequest>,
    ) -> Result<Response<UnpublishVirtualCameraResponse>, Status> {
        // let target_camera_name = request.get_ref().camera_name.clone();

        // println!("unpublish virtual camera: {}", target_camera_name);

        Ok(Response::new(UnpublishVirtualCameraResponse {}))
    }
}

// webviewが読み込むリソースについてのdoc
// https://v2.tauri.app/ja/reference/config/
// tauri.conf.jsonのfrontendDistが読み込まれ、エントリポイントにはディレクトリ内に存在するindex.htmlが検索され指定される
// いやviteの開発サーバーから取得されてるっぽい？
// https://v2.tauri.app/ja/develop/

fn main() {
    let (s, r) = crossbeam_channel::unbounded::<Vec<u8>>();

    thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let addr = "127.0.0.1:50051".parse().unwrap();
            let camera_service = MyCameraService::new(s);

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

    thread::spawn(move || {
        let pyvirtualcam = PyVirtualCam::new(1920, 1080, 20).unwrap();

        while let Ok(frame) = r.recv() {
            pyvirtualcam.send(frame);
        }
    });

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
