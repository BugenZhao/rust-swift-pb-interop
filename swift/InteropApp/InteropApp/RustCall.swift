//
//  RustCall.swift
//  InteropApp
//
//  Created by Bugen Zhao on 6/23/21.
//

import Foundation
import SwiftProtobuf

struct RustError: Error {
    public let error: String
}

func extractByteBuffer(_ bb: ByteBuffer) -> (Data?, RustError?) {
    var resError: RustError? = nil
    var resData: Data? = nil

    if let err = bb.err {
        resError = RustError(error: String(cString: err)) // copied
    } else {
        resData = Data(UnsafeRawBufferPointer(start: bb.ptr, count: Int(bb.len))) // copied
    }

    return (resData, resError)
}

// MARK: - Sync

func rustCall<Response: SwiftProtobuf.Message>(_ request: Request) throws -> Response {
    let reqData = try! request.serializedData()
    let resByteBuffer = reqData.withUnsafeBytes { ptr -> ByteBuffer in
        let ptr = ptr.bindMemory(to: UInt8.self).baseAddress
        return rust_call(ptr, UInt(reqData.count))
    }

    let (resData, resError) = extractByteBuffer(resByteBuffer)
    defer { rust_free(resByteBuffer) }

    if let resData = resData {
        let res = try Response(serializedData: resData)
        return res
    } else {
        throw resError!
    }
}


// MARK: - Async

private class WrappedDataCallback {
    private let callback: (Data) -> Void
    private let errorCallback: (RustError) -> Void
    private let onMainThread: Bool

    init(
        callback: @escaping (Data) -> Void,
        errorCallback: @escaping (RustError) -> Void,
        onMainThread: Bool
    ) {
        self.callback = callback
        self.errorCallback = errorCallback
        self.onMainThread = onMainThread
    }

    func run(_ data: Data?, _ error: RustError?) {
        let block = {
            print("swift: running callback on thread `\(Thread.current)`")
            if let error = error {
                self.errorCallback(error)
            } else {
                self.callback(data!)
            }
        }
        if onMainThread {
            DispatchQueue.main.async(execute: block)
        } else {
            block()
        }
    }
}

private func byteBufferCallback(callbackPtr: UnsafeRawPointer?, resByteBuffer: ByteBuffer) -> Void {
    let (resData, resError) = extractByteBuffer(resByteBuffer)
    defer { rust_free(resByteBuffer) }
    let dataCallback: WrappedDataCallback = Unmanaged.fromOpaque(callbackPtr!).takeRetainedValue()

    print("swift: before running callback on thread `\(Thread.current)`")
    dataCallback.run(resData, resError)
}

func rustCallAsync<Response: SwiftProtobuf.Message>(
    _ request: Request,
    onMainThread: Bool = true,
    closure: @escaping (Response) -> Void
) {
    let dataCallback = WrappedDataCallback(
        callback: { (resData: Data) in
            let res = try! Response(serializedData: resData)
            closure(res)
        },
        errorCallback: { e in print("rustCallAsync error: \(e)") },
        onMainThread: onMainThread
    )
    let dataCallbackPtr = Unmanaged.passRetained(dataCallback).toOpaque()

    let rustCallback = RustCallback(user_data: dataCallbackPtr, callback: byteBufferCallback)
    let reqData = try! request.serializedData()
    reqData.withUnsafeBytes { ptr -> Void in
        let ptr = ptr.bindMemory(to: UInt8.self).baseAddress
        rust_call_async(ptr, UInt(reqData.count), rustCallback)
    }
}
