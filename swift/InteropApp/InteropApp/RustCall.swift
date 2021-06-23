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
