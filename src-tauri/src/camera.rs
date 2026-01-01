use opencv::core::Mat;
use opencv::imgcodecs;
use opencv::imgproc;
use opencv::prelude::*;
use opencv::videoio::{VideoCapture, VideoCaptureTrait};
// use serde::{Deserialize, Serialize};
use std::fs::File;
use std::path::Path;
// use std::sync::mpsc;
use crossbeam_channel::unbounded;
use std::thread;
use std::thread::sleep;
use std::time::Duration;

#[derive(Debug, Clone)]
pub struct Camera {
    rx: crossbeam_channel::Receiver<Mat>,
}

impl Camera {
    pub fn new(id: i32) -> Result<Self, String> {
        let mut vcap = VideoCapture::new(id, opencv::videoio::CAP_ANY)
            .map_err(|_| "can not open camera".to_owned())?;

        let (tx, rx) = unbounded();

        thread::spawn(move || loop {
            let mut frame = Mat::default();
            let success = VideoCaptureTrait::read(&mut vcap, &mut frame)
                .map_err(|_| "can not read frame".to_owned())
                .unwrap();

            if !success || frame.empty() {
                // return Err("can not read frame".to_owned());
                panic!("can not read frame");
            }

            // BGR to RGB
            // let mut rgb_frame = Mat::default();
            // imgproc::cvt_color(
            //     &frame,
            //     &mut rgb_frame,
            //     imgproc::COLOR_BGR2RGB,
            //     0,
            //     opencv::core::AlgorithmHint::ALGO_HINT_DEFAULT,
            // )
            // .map_err(|_| "can not convert frame".to_owned())
            // .unwrap();
            tx.send(frame).unwrap();
            sleep(Duration::from_millis(1000 / 60));
        });

        Ok(Self { rx })
    }

    pub fn read(&mut self) -> Result<Mat, String> {
        self.rx.recv().map_err(|_| "can not read frame".to_owned())
    }
}
