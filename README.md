# Vite
- rootのindex.htmlでelm.jsを読み込むとviteがバンドルしてくれるが、その際に余計なimportを挿入してしまう。hmlt scriptタグでimportを含むjsを読み込むにはtype="module"を指定する必要があるが、それだとElmランタイムが必要とするthisオブジェクトが定義されずfailする。
- vite.config.tsで依存関係を解決しないファイルを指定できるらしいがうまく効かせられなかったため、bundleの生成ファイルを一旦publicディレクトリに出力し、elmのコードは別でelm-watch からpublicに生成するようにし、rootのindex.htmlではpublicディレクトリで動作するパスで作成することでviteのバンドルに巻き込まれず、かつ、アプリ動作時にはリソースを読み込めるようにして解決した。
    - あ、違うや
    - viteはpublicディレクトリに配置したリソースをバンドルせず、root直下のリソースとして扱えるようにしてくれるっぽい
    - https://ja.vite.dev/guide/assets#the-public-directory
- 依存関係を除くのではなく、生成した後にディレクトリごと除去するという方法もあるらしい。なんにせよviteの依存関係除去はうまく動作させられないようだ
    - https://cofus.blog/posts/exclude-directories-under-public-when-building-with-vite

## in project root, execute the following commands in terminal separatedly
    - protoc --elm_out=src/elm/src proto/camera.proto
    - npx elm-watch hot
    - npm run tauri dev