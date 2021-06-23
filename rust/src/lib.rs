mod protos;

use protobuf::Message;
use protos::DataModel::*;
use std::{mem, slice};

unsafe fn parse_from_raw(data: *const u8, len: usize) -> Request {
    let bytes = slice::from_raw_parts(data, len);
    Request::parse_from_bytes(bytes).unwrap()
}

fn handle_greeting(req: GreetingRequest) -> Box<dyn Message> {
    let res = GreetingResponse {
        text: format!("{}, {}!", req.get_verb(), req.get_name()),
        ..Default::default()
    };
    Box::new(res)
}

fn dispatch_request(req: Request) -> Vec<u8> {
    use Request_oneof_request::*;
    let response = match req.request.unwrap() {
        greeting(r) => handle_greeting(r),
    };

    let mut response_buf = Vec::with_capacity(response.compute_size() as usize + 1);
    response.write_to_vec(&mut response_buf).unwrap();
    response_buf
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
pub unsafe extern "C" fn rust_free(byte_buffer: ByteBuffer) {
    println!("rust: free buffer {:?}", byte_buffer);
    let ByteBuffer { ptr, len, cap } = byte_buffer;
    let buf = Vec::from_raw_parts(ptr as *mut u8, len, cap);
    drop(buf)
}
