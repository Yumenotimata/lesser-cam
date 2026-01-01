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
    SetVirtualCameraConfigRequest, SetVirtualCameraConfigResponse, UnpublishVirtualCameraRequest,
    UnpublishVirtualCameraResponse,
};
use opencv::{
    core::{MatTraitConstManual, Vector},
    imgcodecs, imgproc,
    videoio::{VideoCapture, VideoCaptureTrait},
};

use opencv::core::Mat;
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

use vmask_lib::{python_ffi::enumerate_cameras, Camera, PyVirtualCam};
// use ws::{connect, CloseCode};

#[derive(Debug, Clone)]
struct VirtualCameraConfig {
    // 0.0 ~ 1.0
    pub resolution_ratio: f32,
}
use tokio::task::spawn_blocking;

struct MyCameraServiceState {
    opend_camera_map: HashMap<String, Camera, BuildHasherDefault<FxHasher>>,
    virtual_camera_configs: HashMap<String, VirtualCameraConfig>,
    available_camera_list: Vec<(i32, String)>,
    virtual_camera_thread: Option<thread::JoinHandle<()>>,
}

impl MyCameraServiceState {
    fn new() -> Self {
        Self {
            opend_camera_map: HashMap::default(),
            virtual_camera_configs: HashMap::default(),
            available_camera_list: Vec::new(),
            virtual_camera_thread: None,
        }
    }
}

struct MyCameraService {
    stream_thread: Option<thread::JoinHandle<()>>,
    state: Arc<Mutex<MyCameraServiceState>>,
}

impl MyCameraService {
    fn new() -> Self {
        Self {
            stream_thread: None,
            state: Arc::new(Mutex::new(MyCameraServiceState::new())),
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
        let available_camera_list = enumerate_cameras().unwrap().into_iter().collect();

        let mut state = self.state.lock().await;
        state.available_camera_list = available_camera_list;

        Ok(Response::new(GetCameraListResponse {
            camera_list: state
                .available_camera_list
                .iter()
                .map(|(_, name)| name.clone())
                .collect(),
        }))
    }

    async fn get_latest_camera_frame(
        &self,
        request: Request<GetLatestCameraFrameRequest>,
    ) -> Result<Response<GetLatestCameraFrameResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        println!("cameraName: {}", target_camera_name);

        let mut state = self.state.lock().await;

        let target_camera_id = state
            .available_camera_list
            .iter()
            .find(|(_, name)| **name == target_camera_name)
            .map(|(id, _)| *id);

        if let Some(target_camera_id) = target_camera_id {
            // 指定されたカメラが開いていない場合は開いてキャッシュしておく
            let camera = state
                .opend_camera_map
                .entry(target_camera_name.clone())
                .or_insert_with(|| Camera::new(target_camera_id).unwrap());

            let mat = camera.read().unwrap();

            let mut frame = Vector::new();
            imgcodecs::imencode_def(".jpeg", &mat, &mut frame).unwrap();

            let frame: Vec<u8> = frame.into_iter().collect();

            Ok(Response::new(GetLatestCameraFrameResponse { frame }))
        } else {
            Err(Status::not_found("camera not found"))
        }
    }

    async fn get_latest_virtual_camera_frame(
        &self,
        request: Request<GetLatestVirtualCameraFrameRequest>,
    ) -> Result<Response<GetLatestVirtualCameraFrameResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        let mut state = self.state.lock().await;

        let target_camera_id = state
            .available_camera_list
            .iter()
            .find(|(_, name)| **name == target_camera_name)
            .map(|(id, _)| *id);

        if let Some(target_camera_id) = target_camera_id {
            let config = state
                .virtual_camera_configs
                .entry(target_camera_name.clone())
                .or_insert_with(|| VirtualCameraConfig {
                    resolution_ratio: 1.0,
                })
                .clone();

            // 指定されたカメラが開いていない場合は開いてキャッシュしておく
            let camera = state
                .opend_camera_map
                .entry(target_camera_name.clone())
                .or_insert_with(|| Camera::new(target_camera_id).unwrap());

            let mat = camera.read().unwrap();
            let mut resized = Mat::default();

            let scale = clamp(config.resolution_ratio, 0.0, 1.0) as f64;

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
        } else {
            Err(Status::not_found("camera not found"))
        }
    }

    async fn set_virtual_camera_config(
        &self,
        request: Request<SetVirtualCameraConfigRequest>,
    ) -> Result<Response<SetVirtualCameraConfigResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        let mut state = self.state.lock().await;
        state
            .virtual_camera_configs
            .entry(target_camera_name)
            .and_modify(|config| config.resolution_ratio = request.get_ref().resolution_ratio)
            .or_insert_with(|| VirtualCameraConfig {
                resolution_ratio: request.get_ref().resolution_ratio,
            });

        println!(
            "set virtual camera config: {:?}",
            state.virtual_camera_configs
        );

        Ok(Response::new(SetVirtualCameraConfigResponse {}))
    }

    async fn publish_virtual_camera(
        &self,
        request: Request<PublishVirtualCameraRequest>,
    ) -> Result<Response<PublishVirtualCameraResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        let mut state = self.state.lock().await;
        let target_camera_id = state
            .available_camera_list
            .iter()
            .find(|(_, name)| **name == target_camera_name)
            .map(|(id, _)| *id);

        println!(
            "{:?} target_camera_id: {:?}",
            target_camera_name, target_camera_id
        );

        if let Some(target_camera_id) = target_camera_id {
            let config = state
                .virtual_camera_configs
                .entry(target_camera_name.clone())
                .or_insert_with(|| VirtualCameraConfig {
                    resolution_ratio: 1.0,
                })
                .clone();

            let camera = state
                .opend_camera_map
                .entry(target_camera_name.clone())
                .or_insert_with(|| Camera::new(target_camera_id).unwrap());

            let mut camera_clone = camera.clone();

            let h = thread::spawn(move || {
                let mut vcap = VideoCapture::new(0, opencv::videoio::CAP_ANY).unwrap();
                let py_virtual_camera = PyVirtualCam::new(16, 16, 30).unwrap();

                let mut c = 0;
                println!("py_virtual_camera: {:?}", py_virtual_camera);

                loop {
                    // let mat = camera_clone.read().unwrap();
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
                    // .unwrap();

                    // let mut frame = Vector::new();
                    // imgcodecs::imencode_def(".jpeg", &resized, &mut frame).unwrap();
                    let mut frame = Mat::default();
                    vcap.read(&mut frame).unwrap();
                    let frame = frame.data_bytes().unwrap().to_vec();

                    // let frame = mat.data_bytes().unwrap().to_vec();
                    // let frame: Vec<u8> = resized.data().to_vec();

                    py_virtual_camera.send(frame);
                    println!("send frame");
                    c += 1;
                }
            });

            // let mat = camera.read().unwrap();
            // let mut resized = Mat::default();

            // let config = state
            //     .virtual_camera_configs
            //     .entry(target_camera_name.clone())
            //     .or_insert_with(|| VirtualCameraConfig {
            //         resolution_ratio: 1.0,
            //     })
            //     .clone();

            // let scale = clamp(config.resolution_ratio, 0.0, 1.0) as f64;

            // imgproc::resize(
            //     &mat,
            //     &mut resized,
            //     opencv::core::Size::default(),
            //     scale,
            //     scale,
            //     imgproc::INTER_AREA,
            // )
            // .unwrap();

            // let mut frame = Vector::new();
            // imgcodecs::imencode_def(".jpeg", &resized, &mut frame).unwrap();

            // let frame: Vec<u8> = frame.into_iter().collect();
        };

        Ok(Response::new(PublishVirtualCameraResponse {}))
    }

    async fn unpublish_virtual_camera(
        &self,
        request: Request<UnpublishVirtualCameraRequest>,
    ) -> Result<Response<UnpublishVirtualCameraResponse>, Status> {
        let target_camera_name = request.get_ref().camera_name.clone();

        println!("unpublish virtual camera: {}", target_camera_name);

        Ok(Response::new(UnpublishVirtualCameraResponse {}))
    }
}

// webviewが読み込むリソースについてのdoc
// https://v2.tauri.app/ja/reference/config/
// tauri.conf.jsonのfrontendDistが読み込まれ、エントリポイントにはディレクトリ内に存在するindex.htmlが検索され指定される
// いやviteの開発サーバーから取得されてるっぽい？
// https://v2.tauri.app/ja/develop/

fn main() {
    thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            // let r = tokio::spawn(async {
            //     thread::spawn(|| {
            //         let pyvirtualcam = PyVirtualCam::new(320, 240, 20).unwrap();

            //         let mut c: u32 = 0;
            //         loop {
            //             // while true {
            //             pyvirtualcam.send(vec![(c % 255) as u8; 320 * 240 * 3]);
            //             c += 1;
            //             // }
            //         }
            //     });
            // })
            // .await;

            // while true {}

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
