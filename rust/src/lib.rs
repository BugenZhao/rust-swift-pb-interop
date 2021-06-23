mod protos;

mod async_dispatch;
mod async_handlers;
mod sync_dispatch;
mod sync_handlers;

use crate::{
    async_dispatch::{dispatch_request_async, RustCallback},
    sync_dispatch::dispatch_request,
};
use protobuf::Message;
use protos::DataModel::*;
use std::{mem, slice};

unsafe fn parse_from_raw(data: *const u8, len: usize) -> Request {
    let bytes = slice::from_raw_parts(data, len);
    Request::parse_from_bytes(bytes).expect("invalid request")
}

#[repr(C)]
#[derive(Debug)]
pub struct ByteBuffer {
    pub ptr: *const u8,
    pub len: usize,
    pub cap: usize,
}

impl From<Vec<u8>> for ByteBuffer {
    fn from(v: Vec<u8>) -> Self {
        let ret = Self {
            ptr: v.as_ptr(),
            len: v.len(),
            cap: v.capacity(),
        };
        println!("rust: new buffer {:?}", ret);
        mem::forget(v);
        ret
    }
}

/// # Safety
/// totally unsafe
#[no_mangle]
pub unsafe extern "C" fn rust_call(data: *const u8, len: usize) -> ByteBuffer {
    let request = parse_from_raw(data, len);
    println!("rust: request {:?}", request);
    let response_buf = dispatch_request(request);
    ByteBuffer::from(response_buf)
}

/// # Safety
/// totally unsafe
#[no_mangle]
pub unsafe extern "C" fn rust_call_async(data: *const u8, len: usize, callback: RustCallback) {
    let request = parse_from_raw(data, len);
    println!("rust: async request {:?}", request);
    dispatch_request_async(request, callback);
}

/// # Safety
/// totally unsafe
#[no_mangle]
pub unsafe extern "C" fn rust_free(byte_buffer: ByteBuffer) {
    println!("rust: free buffer {:?}", byte_buffer);
    let ByteBuffer { ptr, len, cap } = byte_buffer;
    let buf = Vec::from_raw_parts(ptr as *mut u8, len, cap);
    drop(buf)
}
