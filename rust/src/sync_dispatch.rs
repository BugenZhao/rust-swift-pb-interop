use crate::protos::DataModel::*;
use crate::sync_handlers::*;

pub fn dispatch_request(req: Request) -> Vec<u8> {
    use Request_oneof_sync_req::*;
    let response = match req.sync_req.expect("no sync req") {
        greeting(r) => handle_greeting(r),
        sync_backtrace(r) => handle_backtrace(r),
    };

    let mut response_buf = Vec::with_capacity(response.compute_size() as usize + 1);
    response.write_to_vec(&mut response_buf).unwrap();
    response_buf
}
