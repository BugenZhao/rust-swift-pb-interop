use crate::protos::DataModel::*;
use protobuf::Message;

pub async fn handle_sleep(req: SleepRequest) -> Box<dyn Message> {
    tokio::time::sleep(tokio::time::Duration::from_millis(req.millis)).await;
    let res = SleepResponse {
        text: format!("awake after {} milliseconds", req.millis),
        ..Default::default()
    };
    Box::new(res)
}

pub async fn handle_backtrace(_req: BacktraceRequest) -> Box<dyn Message> {
    let bt = backtrace::Backtrace::new();
    let res = BacktraceResponse {
        text: format!("{:?}", bt),
        ..Default::default()
    };
    Box::new(res)
}
