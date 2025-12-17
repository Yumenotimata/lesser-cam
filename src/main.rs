mod camera {
    tonic::include_proto!("camera");
}

use std::thread::{self, sleep};

use camera::{
    OpenCameraRequest, OpenCameraResponse,
    camera_service_server::{CameraService, CameraServiceServer},
};
use tonic::{Request, Response, Status};
use tonic_reflection::server::Builder;
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;
use web_view::{Content, run};

struct MyCameraService {}

#[tonic::async_trait]
impl CameraService for MyCameraService {
    async fn open_camera(
        &self,
        request: Request<OpenCameraRequest>,
    ) -> Result<Response<OpenCameraResponse>, Status> {
        println!("Open camera: {}", request.get_ref().name);
        Ok(Response::new(OpenCameraResponse {
            message: String::from("Hello, world!"),
        }))
    }
}

fn main() {
    thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let addr = "127.0.0.1:50051".parse().unwrap();
            let camera_service = MyCameraService {};

            // gRPC-web対応
            let allow_cors = CorsLayer::new()
                .allow_origin(tower_http::cors::Any)
                .allow_headers(tower_http::cors::Any)
                .allow_methods(tower_http::cors::Any);

            // let greeter = tower::ServiceBuilder::new()
            //     .layer(tower_http::cors::CorsLayer::new())
            //     .layer(tonic_web::GrpcWebLayer::new())
            //     .into_inner();

            tonic::transport::Server::builder()
                .accept_http1(true)
                // .add_service(greeter)
                .layer(allow_cors)
                .layer(GrpcWebLayer::new())
                // .layer(allow_cors)
                // .layer(GrpcWebLayer::new())
                .add_service(CameraServiceServer::new(camera_service))
                // .add_service(
                //     Builder::configure()
                //         .register_encoded_file_descriptor_set(tonic::include_file_descriptor_set!(
                //             "camera_descriptor"
                //         ))
                //         .build()
                //         .unwrap(),
                // )
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
        {runtimejs}
        {websocketjs}
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
        mainjs = include_str!("../js/main.js"),
        runtimejs = include_str!("../js/runtime.js"),
        websocketjs = include_str!("../js/web_socket.js"),
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
