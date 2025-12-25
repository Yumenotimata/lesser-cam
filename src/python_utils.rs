use pyo3::ffi::c_str;
use pyo3::prelude::*;
use pyo3::types::PyList;

pub fn enumerate_cameras() -> Result<Vec<(i32, String)>, PyErr> {
    Python::attach(|py| {
        let python_ffi = PyModule::from_code(
            py,
            c_str!(include_str!("python-utils.py")),
            c"python-utils.py",
            c"python-utils",
        )?;
        let r = python_ffi.getattr("enumerate_cameras")?.call1(())?;
        r.extract::<Vec<(i32, String)>>()
    })
}

pub struct PyVirtualCam {
    width: u32,
    height: u32,
    fps: u32,
    py_virtual_cam: Py<PyAny>,
    py_numpy_module: Py<PyModule>,
}

impl PyVirtualCam {
    pub fn new(width: u32, height: u32, fps: u32) -> Result<PyVirtualCam, PyErr> {
        let py_virtual_cam = Python::attach(|py| {
            let py_virtual_cam_module = PyModule::import(py, "pyvirtualcam").unwrap();
            let py_virtual_cam_class = py_virtual_cam_module.getattr("Camera").unwrap();

            // pyvirtualcamはコンテキストマネージャーとして実装されているので
            // 手動で__enter__してrustの呼び出しを跨いで同じpythonオブジェクトを保持できるようにする
            // コンテキストマネージャの扱い方についての公式リファレンス
            // https://pyo3.rs/v0.27.2/python-from-rust/calling-existing-code.html
            // pyo3は'pyライフタイムを用いてrustの安全性を確保しつつ効率的な実装をしているが、
            // 'pyライフタイムはPython::attach内部でしか与えられないので、unbindしてBound<'py>を'pyライフタイムに依存しないPyに変換する
            // Pyはライフタイムに依存しないが、実行時に安全性のチェックが入るため多少のオーバーヘッドがかかるのと、ほぼ全てのメソッドにトークンpyが必要になる
            let py_virtual_cam_ctx = py_virtual_cam_class.call1((width, height, fps)).unwrap();

            py_virtual_cam_ctx
                .call_method0("__enter__")
                .unwrap()
                .unbind()
        });

        let py_numpy_module = Python::attach(|py| PyModule::import(py, "numpy").unwrap().unbind());

        Ok(PyVirtualCam {
            width,
            height,
            fps,
            py_virtual_cam,
            py_numpy_module,
        })
    }

    pub fn send(&self, frame: Vec<u8>) {
        // println!("{:#?}", frame);
        // todo!();
        // -> Result<(), PyErr> {
        let r = Python::attach(|py| {
            let frame = PyList::new(py, frame).unwrap();
            let frame = self
                .py_numpy_module
                .call_method1(py, "array", (frame,))
                .unwrap();
            let frame = frame.call_method1(py, "astype", ("uint8",)).unwrap();
            let frame = frame
                .call_method1(py, "reshape", (self.height, self.width, 3))
                .unwrap();

            self.py_virtual_cam
                .call_method1(py, "send", (frame,))
                .unwrap()
        });
        println!("send result: {:?}", r);
    }
}
