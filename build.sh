#!/bin/sh

echo ">>>>> Swift PB"
protoc --swift_out=swift/InteropApp/InteropApp/ -I protos/ protos/DataModel.proto

echo ">>>>> Rust"
$HOME/.cargo/bin/cargo build --manifest-path rust/Cargo.toml --release
cp rust/target/release/librust.a out/libs
cp rust/bindings.h out/include
