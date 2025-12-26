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
    PyVirtualCam, Request, RuntimeRequest, RuntimeResponse, ServerState, SharedServerState,
    handle_runtime_request,
};
use web_view::*;

fn main() {
    // Elmで生成されたJsをWebViewで表示
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
        elmjs = include_str!("../elm/dist/elm.js"),
        mainjs = include_str!("../js/main.js"),
        css = include_str!("../css/main.css"),
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
