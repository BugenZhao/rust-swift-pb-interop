use crate::{async_handlers::*, protos::DataModel::*, ByteBuffer};
use lazy_static::lazy_static;
use std::{ffi::c_void, mem};
use tokio::runtime::Runtime;

lazy_static! {
    static ref RUNTIME: Runtime = Runtime::new().expect("failed to create tokio runtime");
}

#[repr(C)]
pub struct RustCallback {
    pub user_data: *const c_void,
    pub callback: extern "C" fn(*const c_void, ByteBuffer),
}
unsafe impl Send for RustCallback {}

impl RustCallback {
    /// # Safety
    /// total unsafe
    pub unsafe fn new(user_data: *const c_void, callback: *const c_void) -> Self {
        Self {
            user_data,
            callback: mem::transmute(callback),
        }
    }

    pub fn run(self, byte_buffer: ByteBuffer) {
        (self.callback)(self.user_data, byte_buffer)
    }
}

pub fn dispatch_request_async(req: Request, callback: RustCallback) {
    RUNTIME.spawn(async move {
        use Request_oneof_async_req::*;
        let response = match req.async_req.expect("no async req") {
            sleep(r) => handle_sleep(r).await,
            async_backtrace(r) => handle_backtrace(r).await,
        };

        let mut response_buf = Vec::with_capacity(response.compute_size() as usize + 1);
        response.write_to_vec(&mut response_buf).unwrap();

        let byte_buffer = ByteBuffer::from(response_buf);
        callback.run(byte_buffer);
    });
}
