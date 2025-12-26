use std::env;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // tonic_build::configure()
    //     .build_server(true)
    //     .file_descriptor_set_path(
    //         PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR is not set"))
    //             .join("camera_descriptor.bin"),
    //     )
    //     .compile_protos(&["../proto/camera.proto"], &["../proto"])?;

    tonic_prost_build::compile_protos("../proto/camera.proto").unwrap();
    tauri_build::build();

    Ok(())
}
