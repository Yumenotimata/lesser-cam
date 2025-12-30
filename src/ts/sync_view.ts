// 全画面遷移時の再レイアウト
import { getCurrentWindow } from "@tauri-apps/api/window";

const appWindow = getCurrentWindow();

const syncViewport = async () => {
    const size = await appWindow.innerSize();

    document.documentElement.style.setProperty(
        "--vw",
        `${size.width}px`
    );
    document.documentElement.style.setProperty(
        "--vh",
        `${size.height}px`
    );
};

appWindow.onResized(syncViewport);

syncViewport();