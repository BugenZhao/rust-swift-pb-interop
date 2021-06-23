use crate::protos::DataModel::*;
use protobuf::Message;

pub fn handle_greeting(req: GreetingRequest) -> Box<dyn Message> {
    let res = GreetingResponse {
        text: format!("{}, {}!", req.get_verb(), req.get_name()),
        ..Default::default()
    };
    Box::new(res)
}

pub fn handle_backtrace(_req: BacktraceRequest) -> Box<dyn Message> {
    let bt = backtrace::Backtrace::new();
    let res = BacktraceResponse {
        text: format!("{:?}", bt),
        ..Default::default()
    };
    Box::new(res)
}
