#!/bin/sh

echo ">>>>> Swift PB"
protoc --swift_out=swift/InteropApp/InteropApp/ -I protos/ protos/DataModel.proto

echo ">>>>> Rust macOS"
$HOME/.cargo/bin/cargo build --manifest-path rust/Cargo.toml --release
cp rust/target/release/librust.a out/libs/librustmacos.a
cp rust/bindings.h out/include

echo ">>>>> Rust iOS"
$HOME/.cargo/bin/cargo lipo --manifest-path rust/Cargo.toml --release
cp rust/target/universal/release/librust.a out/libs/librustios.a
