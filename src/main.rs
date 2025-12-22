extern crate web_view;

use std::{
    net::SocketAddr,
    sync::{Arc, Mutex},
    thread,
};

use axum::{
    Router,
    extract::{
        State, WebSocketUpgrade,
        ws::{Message, WebSocket},
    },
    response::Response,
    routing::get,
};
use lesser_cam::{
    Request, RuntimeRequest, RuntimeResponse, ServerState, SharedServerState,
    handle_runtime_request,
};
use web_view::*;

fn main() {
    let runtime_message = RuntimeRequest {
        uuid: 4,
        message: Request::GetCameraList {},
    };

    println!(
        "runtime_message: {:#?}",
        serde_json::to_string(&runtime_message).unwrap()
    );

    // WebViewがメインスレッドじゃないと動かないのでaxumは別スレッド
    thread::spawn(|| {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let state = Arc::new(Mutex::new(ServerState::default()));

            let app = Router::new()
                .route("/ws", get(ws_handler))
                .with_state(state);

            let addr = SocketAddr::from(([127, 0, 0, 1], 8000));
            println!("Listening on http://{}", addr);
            axum::Server::bind(&addr)
                .serve(app.into_make_service())
                .await
                .unwrap();
        });
    });

    // Elmで生成されたJsをWebViewで表示
    launch_web_view();
}

async fn ws_handler(ws: WebSocketUpgrade, State(state): State<SharedServerState>) -> Response {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(mut ws: WebSocket, mut state: SharedServerState) {
    while let Some(msg) = ws.recv().await {
        if let Ok(msg) = msg {
            match msg {
                Message::Text(json_str) => {
                    println!("Received: {}", json_str);
                    let msg: RuntimeRequest = serde_json::from_str(&json_str).unwrap();
                    println!("Received: {:#?}", msg);

                    // もしレスポンスがあるなら、送り元のuuidを付けて返す
                    if let Some(response) = handle_runtime_request(&msg, &mut state) {
                        let response_msg = RuntimeResponse::new(msg.uuid, response);
                        ws.send(Message::Text(serde_json::to_string(&response_msg).unwrap()))
                            .await
                            .unwrap();
                        // println!("Response: {:#?}", response_msg);
                    }
                }
                Message::Close(_) => {
                    break;
                }
                _ => {}
            }
        } else {
            break;
        }
    }
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
        {canvasjs}
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
        canvasjs = include_str!("../js/canvas.js"),
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
