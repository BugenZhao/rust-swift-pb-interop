//
//  RustCall.swift
//  InteropApp
//
//  Created by Bugen Zhao on 6/23/21.
//

import Foundation
import SwiftProtobuf

// MARK: - Sync

func rustCall<Response: SwiftProtobuf.Message>(_ request: Request) -> Response {
    let reqData = try! request.serializedData()
    let resByteBuffer = reqData.withUnsafeBytes { ptr -> ByteBuffer in
        let ptr = ptr.bindMemory(to: UInt8.self).baseAddress
        return rust_call(ptr, UInt(reqData.count))
    }
    defer { rust_free(resByteBuffer) }
    let resData = Data(UnsafeRawBufferPointer(start: resByteBuffer.ptr, count: Int(resByteBuffer.len))) // copied
    let res = try! Response(serializedData: resData)
    return res
}


// MARK: - Async

private class WrappedDataCallback {
    private let callback: (Data) -> Void
    private let onMainThread: Bool

    init(_ callback: @escaping (Data) -> Void, onMainThread: Bool) {
        self.callback = callback
        self.onMainThread = onMainThread
    }

    func run(_ data: Data) {
        let block = {
            print("swift: running callback on thread `\(Thread.current)`")
            self.callback(data)
        }
        if onMainThread {
            DispatchQueue.main.async(execute: block)
        } else {
            block()
        }
    }
}

private func byteBufferCallback(callbackPtr: UnsafeRawPointer?, resByteBuffer: ByteBuffer) -> Void {
    let resData = Data(UnsafeRawBufferPointer(start: resByteBuffer.ptr, count: Int(resByteBuffer.len))) // copied
    defer { rust_free(resByteBuffer) }
    let dataCallback: WrappedDataCallback = Unmanaged.fromOpaque(callbackPtr!).takeRetainedValue()
    print("swift: before running callback on thread `\(Thread.current)`")
    dataCallback.run(resData)
}

func rustCallAsync<Response: SwiftProtobuf.Message>(
    _ request: Request,
    onMainThread: Bool = true,
    closure: @escaping (Response) -> Void
) {
    let dataCallback = WrappedDataCallback({ (resData: Data) in
        let res = try! Response(serializedData: resData)
        closure(res)
    }, onMainThread: onMainThread)
    let dataCallbackPtr = Unmanaged.passRetained(dataCallback).toOpaque()

    let rustCallback = RustCallback(user_data: dataCallbackPtr, callback: byteBufferCallback)
    let reqData = try! request.serializedData()
    reqData.withUnsafeBytes { ptr -> Void in
        let ptr = ptr.bindMemory(to: UInt8.self).baseAddress
        rust_call_async(ptr, UInt(reqData.count), rustCallback)
    }
}
