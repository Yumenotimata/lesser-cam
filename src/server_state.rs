use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use axum::extract::ws::{Message, WebSocket};
use opencv::{
    core::{MatTraitConstManual, VecN, Vector, VectorToVec},
    imgcodecs,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::{Camera, python_utils};

pub type SharedServerState = Arc<Mutex<ServerState>>;

pub struct ServerState {
    opened_cameras: HashMap<i32, Camera>,
}

impl Default for ServerState {
    fn default() -> Self {
        Self {
            opened_cameras: HashMap::new(),
        }
    }
}

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
    OpenCamera { name: String },
    GetCameraList {},
    GetCameraImage { uuid: i32 },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum Response {
    CameraList(Vec<String>),
    Camera(i32),
    CameraImage(Vec<u8>),
}

fn handle_request(request: Request, state: &mut SharedServerState) -> Option<Response> {
    match request {
        Request::OpenCamera { name } => {
            let target_camera = python_utils::enumerate_cameras()
                .unwrap()
                .into_iter()
                .find(|(_, n)| *n == name)
                .map(|(id, _)| id);

            if let Some(id) = target_camera {
                let camera = Camera::new(id).unwrap();

                // TODO: 重複があるならエラーを返すべき
                state.lock().unwrap().opened_cameras.insert(id, camera);

                Some(Response::Camera(id))
            } else {
                None
            }
        }
        Request::GetCameraList {} => {
            println!("Get camera list");
            let cameras = python_utils::enumerate_cameras()
                .unwrap()
                .into_iter()
                .map(|(_, name)| name)
                .collect();

            Some(Response::CameraList(cameras))
        }
        Request::GetCameraImage { uuid } => {
            let frame = {
                let mut camera_mutex = state.lock().unwrap();
                let camera = camera_mutex.opened_cameras.get_mut(&uuid)?;
                camera.read().unwrap()
            };

            // let mut buffer = Vector::new();
            // imgcodecs::imencode_def(".bmp", &frame, &mut buffer).unwrap();

            let frame_bytes = frame.data_bytes().unwrap();
            let frame_vec: Vec<u8> = frame_bytes.into_iter().map(|s| *s).collect();
            // let frame_vec: Vec<Vec<u8>> = frame.to_vec_2d().unwrap();
            // let frame_vec: Vec<u8> = frame_vec.into_iter().flatten().collect();
            // let frame_vec = vec![];
            Some(Response::CameraImage(frame_vec))
        }
    }
}
