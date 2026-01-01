fn main() {
    tonic_prost_build::compile_protos("../proto/camera.proto").unwrap();
    // protoファイルが変更されたらgRPCのコードを再生成
    println!("cargo:rerun-if-changed=proto/camera.proto");

    tauri_build::build()
}
