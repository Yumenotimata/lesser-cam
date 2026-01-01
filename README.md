# Vite
- rootのindex.htmlでelm.jsを読み込むとviteがバンドルしてくれるが、その際に余計なimportを挿入してしまう。hmlt scriptタグでimportを含むjsを読み込むにはtype="module"を指定する必要があるが、それだとElmランタイムが必要とするthisオブジェクトが定義されずfailする。
- vite.config.tsで依存関係を解決しないファイルを指定できるらしいがうまく効かせられなかったため、bundleの生成ファイルを一旦publicディレクトリに出力し、elmのコードは別でelm-watch からpublicに生成するようにし、rootのindex.htmlではpublicディレクトリで動作するパスで作成することでviteのバンドルに巻き込まれず、かつ、アプリ動作時にはリソースを読み込めるようにして解決した。
    - あ、違うや
    - viteはpublicディレクトリに配置したリソースをバンドルせず、root直下のリソースとして扱えるようにしてくれるっぽい
    - https://ja.vite.dev/guide/assets#the-public-directory
- 依存関係を除くのではなく、生成した後にディレクトリごと除去するという方法もあるらしい。なんにせよviteの依存関係除去はうまく動作させられないようだ
    - https://cofus.blog/posts/exclude-directories-under-public-when-building-with-vite

## setup
    - export LIBCLANG_PATH="/opt/homebrew/opt/llvm/lib"
    - export LD_LIBRARY_PATH="/opt/homebrew/opt/llvm/lib"
    - cargo clean
    - cargo build -vv
    - buf generate
        - brew install bufbuild/buf/buf
        - https://zenn.dev/hisamitsu/articles/4840b068e2bd49

## in project root, execute the following commands in terminal separatedly
    - protoc --elm_out=src/elm/src proto/camera.proto
    - npx elm-watch hot
    - npm run tauri dev


- "  14: std::rt::lang_start::<()>::{closure#0}
  15: std::rt::lang_start_internal
  16: _main
   Compiling opencv v0.97.2
error: failed to run custom build command for `opencv v0.97.2`
note: To improve backtraces for build dependencies, set the CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG=true environment variable to enable debug information generation.

Caused by:
  process didn't exit successfully: `/Users/flukekit/workspace/tauri-elm-app/src-tauri/target/debug/build/opencv-89a6d15db4834ad4/build-script-build` (signal: 6, SIGABRT: process abort signal)
  --- stderr
  dyld[16199]: Library not loaded: @rpath/libLLVM.dylib
    Referenced from: <FAD5036B-52DC-3341-A33B-34BD41AD3312> /usr/local/lib/libclang.dylib
    Reason: tried: '/usr/local/lib/../lib/libLLVM.dylib' (no such file), '/Users/flukekit/workspace/tauri-elm-app/src-tauri/target/debug/deps/libLLVM.dylib' (no such file), '/Users/flukekit/workspace/tauri-elm-app/src-tauri/target/debug/libLLVM.dylib' (no such file), '/Users/flukekit/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/aarch64-apple-darwin/lib/libLLVM.dylib' (no such file), '/Users/flukekit/.rustup/toolchains/stable-aarch64-apple-darwin/lib/libLLVM.dylib' (no such file), '/Users/flukekit/lib/libLLVM.dylib' (no such file), '/usr/local/lib/libLLVM.dylib' (no such file), '/usr/lib/libLLVM.dylib' (no such file, not in dyld cache)

2025-12-29T21:03:25.451289+09:00  WARN overly long loop turn took 1.08813625s (event handling took 1.088064625s): PrimeCaches(End { cancelled: false })"

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 took 11s 
❯ sudo find /usr -name "libclang.dylib"

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 
❯ sudo find /opt -name "libclang.dylib"
/opt/homebrew/Cellar/llvm/21.1.6/lib/libclang.dylib

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 took 2s 
❯ sudo cp /opt/homebrew/Cellar/llvm/21.1.6/lib/libclang.dylib /usr/lib/libclang.dylib
cp: /usr/lib/libclang.dylib: Operation not permitted

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 
❯ sudo cp /opt/homebrew/Cellar/llvm/21.1.6/lib/libclang.dylib /usr/lib/              
cp: /usr/lib/libclang.dylib: Operation not permitted

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 
❯ sudo cp /opt/homebrew/Cellar/llvm/21.1.6/lib/libclang.dylib /usr/local/lib/

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 
❯ sudo find /opt -name "libLLVM.dylib"                                               
/opt/homebrew/Cellar/llvm/21.1.6/lib/libLLVM.dylib

tauri-elm-app/src-tauri on  vanilla [!?] is 📦 v0.1.0 via 🦀 v1.90.0 
❯ sudo cp /opt/homebrew/Cellar/llvm/21.1.6/lib/libLLVM.dylib /usr/local/lib/

tauri-elm-app/src-tauri on  vanilla [!?] is