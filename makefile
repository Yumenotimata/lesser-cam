.PHONY: help
help: makefile
	@tail -n +4 makefile | grep ".PHONY"


node_modules: package.json bun.lockb
	bun install


.PHONY: dev
dev: node_modules
	npx concurrently \
		"npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css --watch" \
		"bun x tauri dev"


.PHONY: dev-elm
dev-elm:
	bun x elm-watch hot


dist/main.js: src/Main.elm | node_modules
	# Use bun if available
	command -v bun >/dev/null \
		&& bun x elm-watch make --optimize \
		|| npx elm-watch make --optimize


.PHONY: build
# Prerequisites are built by Tauri
build: node_modules
	rm -rf dist/main.js
	bun x tauri build

# protobufからelmのクライアントコードを生成
.PHONY: protoc
protoc:
	protoc --elm_out=src proto/camera.proto

.PHONY: clean
clean:
	rm -rf dist/main.js
	rm -rf elm-stuff
	rm -rf node_modules
	rm -rf src-tauri/target
