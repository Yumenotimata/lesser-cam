use serde::{Deserialize, Serialize};
// use stylist::style;
use wasm_bindgen::{prelude::*, Clamped};
use wasm_bindgen_futures::spawn_local;
use web_sys::{console, window, Blob, CanvasRenderingContext2d, HtmlCanvasElement, ImageData};
use yew::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = ["window", "__TAURI__", "core"])]
    async fn invoke(cmd: &str, args: JsValue) -> JsValue;
}

pub enum Msg {
    None,
}

pub struct App {}

impl Component for App {
    type Message = Msg;
    type Properties = ();

    fn create(_ctx: &Context<Self>) -> Self {
        console::log_1(&"hello canvas".into());
        Self {}
    }

    fn update(&mut self, _ctx: &Context<Self>, _msg: Self::Message) -> bool {
        // println!("update");
        false
    }

    fn view(&self, _ctx: &Context<Self>) -> Html {
        // let button_style = style! {
        //     color: white;
        //     background-color: blue;
        // }
        // .unwrap();

        html! {
            <main>
                <div>
                    <FrameViewer ..yew::props!{ Props { name: "f".to_string() } }/>
                </div>
            </main>
        }
    }
}

#[derive(yew::Properties, PartialEq)]
pub struct Props {
    name: String,
}

pub struct FrameViewer {
    canvas: NodeRef,
}

impl Component for FrameViewer {
    type Message = Msg;
    type Properties = Props;

    fn create(_ctx: &Context<Self>) -> Self {
        Self {
            canvas: NodeRef::default(),
        }
    }

    fn rendered(&mut self, _ctx: &Context<Self>, first_render: bool) {
        if !first_render {
            return;
        }

        let canvas: HtmlCanvasElement = self.canvas.cast().expect("canvas not found");

        canvas.set_width(400);
        canvas.set_height(100);

        let ctx = canvas
            .get_context("2d")
            .unwrap()
            .unwrap()
            .dyn_into::<CanvasRenderingContext2d>()
            .unwrap();

        // ctx.set_fill_style_str("red");
        // ctx.fill_rect(0.0, 0.0, 400.0, 100.0);

        let bytes: Vec<u8> = vec![0xffffffffu32; 400 * 100]
            .into_iter()
            .flat_map(|x| x.to_le_bytes())
            .collect();

        console::log_1(&bytes[0].into());
        console::log_1(&bytes[1].into());
        console::log_1(&bytes[2].into());
        console::log_1(&bytes[3].into());
        // let bytes = vec![0xffu8; 400 * 100];
        let image_data = ImageData::new_with_u8_clamped_array(Clamped(&bytes), 400).unwrap();
        ctx.put_image_data(&image_data, 0.0, 0.0).unwrap();

        console::log_1(&"image data".into());
        // let blob = vec![0u8; 100];
        // let blob: JsValue = blob.into();
        // let blob = Blob::new_with_u8_array_sequence(&blob).unwrap();
        // // let image_bitmap = create_image (&blob).unwrap();
        // let window = window().unwrap();
        // let image_bitmap =
        //     window
        //         .create_image_bitmap_with_blob(&blob)
        //         .unwrap()
        //         .then(&Closure::wrap(Box::new(move |image_bitmap| {
        //             ctx.draw_image_with_image_bitmap(&image_bitmap, 0.0, 0.0);
        //         })));
        // ctx.draw_image_with
        // ctx.draw_image_with_image_bitmap(image, dx, dy)
        // ctx.draw_image_with_image_bitmap(&image_bitmap, 0.0, 0.0);
        // ctx.draw_image_with_html_canvas_element(image, dx, dy)

        // ctx.set_fill_style_str("black");
        // ctx.fill_text("hello canvas", 10.0, 50.0).unwrap();
    }

    fn view(&self, _ctx: &Context<Self>) -> Html {
        let props = _ctx.props();
        html! {
            <div>
                <canvas ref={self.canvas.clone()} />
                <p>{props.name.clone()}</p>
            </div>
            // <p>{_}</p>
        }
    }
}
