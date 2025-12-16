use std::sync::{Arc, Mutex};

use serde::Deserialize;

pub type SharedServerState = Arc<Mutex<ServerState>>;

pub struct ServerState {}

#[derive(Debug, Deserialize)]
pub enum Cmd {
    OpenCamera { path: String },
}

pub fn handle_command(cmd: Cmd, state: &mut SharedServerState) {
    match cmd {
        Cmd::OpenCamera { path } => {
            println!("Open camera: {}", path);
        }
    }
}
