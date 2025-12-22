use std::sync::{Arc, Mutex};

use axum::extract::ws::{Message, WebSocket};
use serde::{Deserialize, Serialize};
use serde_json::Value;

pub type SharedServerState = Arc<Mutex<ServerState>>;

pub struct ServerState {}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RuntimeRequest {
    pub uuid: i32,
    // なぜかmessageをResponseにするとパースできない
    pub message: Request,
}

impl RuntimeRequest {
    pub fn new(uuid: i32, message: Request) -> Self {
        Self { uuid, message }
    }
}

#[derive(Debug, Serialize, Clone)]
pub struct RuntimeResponse {
    pub uuid: i32,
    pub message: Response,
}

impl RuntimeResponse {
    pub fn new(uuid: i32, message: Response) -> Self {
        Self { uuid, message }
    }
}

pub fn handle_runtime_request(
    msg: &RuntimeRequest,
    state: &mut SharedServerState,
) -> Option<Response> {
    // let request: Request = msg.message.clone();
    handle_request(msg.message.clone(), state)
}

#[derive(Debug, Deserialize, Clone, Serialize)]
pub enum Request {
    OpenCamera { path: String },
    GetCameraList {},
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum Response {
    CameraList(Vec<String>),
}

fn handle_request(request: Request, state: &mut SharedServerState) -> Option<Response> {
    match request {
        Request::OpenCamera { path } => {
            println!("Open camera: {}", path);
            None
        }
        Request::GetCameraList {} => {
            println!("Get camera list");
            Some(Response::CameraList(vec![
                "okokokokokokokoko cam".to_string(),
            ]))
        }
    }
}
