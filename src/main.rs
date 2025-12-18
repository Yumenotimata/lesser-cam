mod camera {
    tonic::include_proto!("camera");
}

use std::{
    sync::Arc,
    thread::{self, sleep},
};

use camera::{
    OpenCameraRequest, OpenCameraResponse,
    camera_service_server::{CameraService, CameraServiceServer},
};
use tokio::sync::Mutex;
use tonic::{Request, Response, Status};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;
use web_view::{Content, run};

struct CameraServiceState {
    counter: u32,
}

struct MyCameraService {
    state: Arc<Mutex<CameraServiceState>>,
}

impl MyCameraService {
    fn new() -> Self {
        Self {
            state: Arc::new(Mutex::new(CameraServiceState { counter: 0 })),
        }
    }
}

#[tonic::async_trait]
impl CameraService for MyCameraService {
    async fn open_camera(
        &self,
        request: Request<OpenCameraRequest>,
    ) -> Result<Response<OpenCameraResponse>, Status> {
        let mut state = self.state.lock().await;
        state.counter += 1;

        println!("Open camera: {}", request.get_ref().name);
        Ok(Response::new(OpenCameraResponse {
            message: format!("Hello, world! {}", state.counter),
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

            tonic::transport::Server::builder()
                .accept_http1(true)
                .layer(allow_cors)
                .layer(GrpcWebLayer::new())
                .add_service(CameraServiceServer::new(camera_service))
                .serve(addr)
                .await
                .unwrap();
        });
    });

    launch_web_view();
}

fn launch_web_view() {
    let size = (700, 400);
    let resizable = true;
    let debug = true;
    let titlebar_transparent = true;
    let frontend_cb = |_webview: &mut _, _arg: &_, _userdata: &mut _| {};
    let userdata = ();

    let html = format!(
        r#"
    <html>
        <head>
        <style>{css}</style>
        <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500|Material+Icons" rel="stylesheet">
        <link rel="stylesheet" href="https://unpkg.com/material-components-web-elm@9.1.0/dist/material-components-web-elm.min.css">
        <script src="https://unpkg.com/material-components-web-elm@9.1.0/dist/material-components-web-elm.min.js"></script>
        <script src="https://unpkg.com/elm-taskport@2.0.1/dist/taskport.min.js"></script>
        <script>
        {elmjs}
        </script>
        </head>
        <body>
        <div id="app"></div>
        <script>
        {mainjs}
        </script>
        </body>
    </html>
    "#,
        css = r#"body { background: #ffffff; }"#,
        elmjs = include_str!("../elm/dist/elm.js"),
        mainjs = include_str!("../js/main.js")
    );

    std::fs::write("index.html", html.clone()).unwrap();

    run(
        "",
        Content::Html(html),
        Some(size),
        resizable,
        debug,
        titlebar_transparent,
        move |mut webview| {
            webview.set_background_color(0.11, 0.12, 0.13, 1.0);
        },
        frontend_cb,
        userdata,
    );
}
