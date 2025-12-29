// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// webviewが読み込むリソース
// https://v2.tauri.app/ja/reference/config/
// tauri.conf.jsonのfrontendDistが読み込まれ、エントリポイントにはディレクトリ内に存在するindex.htmlが検索され指定される
// いやviteの開発サーバーから取得されてるっぽい？
// https://v2.tauri.app/ja/develop/

fn main() {
    less_i_cam_lib::run()
}
