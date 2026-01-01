mod camera {
    tonic::include_proto!("camera");
}

use std::thread;

use tauri_elm_app::PyVirtualCam;
use tonic::transport::Server;
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

use crate::camera::{
    TestRequest, TestResponse,
    camera_service_server::{CameraService, CameraServiceServer},
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
    let h = thread::spawn(|| {
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

    h.join().unwrap();
}
