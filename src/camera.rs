use opencv::core::Mat;
use opencv::imgcodecs;
use opencv::imgproc;
use opencv::prelude::*;
use opencv::videoio::{VideoCapture, VideoCaptureTrait};
// use serde::{Deserialize, Serialize};
use std::fs::File;
use std::path::Path;

pub struct Camera {
    vcap: VideoCapture,
}

impl Camera {
    pub fn new(id: i32) -> Result<Self, String> {
        let vcap = VideoCapture::new(id, opencv::videoio::CAP_ANY)
            .map_err(|_| "can not open camera".to_owned())?;

        Ok(Self { vcap })
    }

    pub fn read(&mut self) -> Result<Mat, String> {
        let mut frame = Mat::default();
        let success = VideoCaptureTrait::read(&mut self.vcap, &mut frame)
            .map_err(|_| "can not read frame".to_owned())?;

        if !success || frame.empty() {
            return Err("can not read frame".to_owned());
        }

        // BGR to RGB
        let mut rgb_frame = Mat::default();
        imgproc::cvt_color(
            &frame,
            &mut rgb_frame,
            imgproc::COLOR_BGR2RGB,
            0,
            opencv::core::AlgorithmHint::ALGO_HINT_DEFAULT,
        )
        .map_err(|_| "can not convert frame".to_owned())?;

        Ok(rgb_frame)
    }
}
