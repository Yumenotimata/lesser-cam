fn main() {
    tonic_prost_build::compile_protos("../proto/camera.proto").unwrap();
    tauri_build::build()
}
