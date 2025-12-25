use std::env;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .file_descriptor_set_path(
            PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR is not set"))
                .join("camera_descriptor.bin"),
        )
        .compile(&["../proto/camera.proto"], &["../proto"])?;

    tauri_build::build();

    Ok(())
}
