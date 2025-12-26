// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
mod camera {
    tonic::include_proto!("camera");
}
use std::thread;

// use http::Response;
use tokio::sync::mpsc;
use tokio::sync::Mutex;
// use tokio_stream::{StreamExt, wrappers::ReceiverStream};
use tonic::transport::Server;
use tonic::{Request, Response, Status};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

use camera::{
    camera_service_server::{CameraService, CameraServiceServer},
    GetCameraListRequest, GetCameraListResponse,
};

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
            camera_list: vec!["A", "B"].into_iter().map(|s| s.to_string()).collect(),
        }))
    }
}
use tonic::service::LayerExt;
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

    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
