//
//  RustCall.swift
//  InteropApp
//
//  Created by Bugen Zhao on 6/23/21.
//

import Foundation
import SwiftProtobuf

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


private typealias ByteBufferCallback = @convention(c) (UnsafeRawPointer?, ByteBuffer) -> Void

private class WrappedDataCallback {
    fileprivate let callback: (Data) -> Void
    init(_ callback: @escaping (Data) -> Void) {
        self.callback = callback
    }
}


func rustCallAsync<Response: SwiftProtobuf.Message>(_ request: Request, closure: @escaping (Response) -> Void) {
    let dataCallback = WrappedDataCallback({ (resData: Data) in
        let res = try! Response(serializedData: resData)
        closure(res)
    })
    let byteBufferCallback: ByteBufferCallback = { callbackPtr, resByteBuffer in
        let resData = Data(UnsafeRawBufferPointer(start: resByteBuffer.ptr, count: Int(resByteBuffer.len))) // copied
        defer { rust_free(resByteBuffer) }
        let dataCallback: WrappedDataCallback = Unmanaged.fromOpaque(callbackPtr!).takeRetainedValue()
        dataCallback.callback(resData)
    }

    let dataCallbackPtr = Unmanaged.passRetained(dataCallback).toOpaque()
    let rustCallback = RustCallback(user_data: dataCallbackPtr, callback: byteBufferCallback)

    let reqData = try! request.serializedData()
    reqData.withUnsafeBytes { ptr -> Void in
        let ptr = ptr.bindMemory(to: UInt8.self).baseAddress
        rust_call_async(ptr, UInt(reqData.count), rustCallback)
    }
}
