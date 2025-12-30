// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

pub mod python_ffi;
pub use python_ffi::*;

pub mod camera;
pub use camera::*;
