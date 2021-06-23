//
//  RustCallTests.swift
//  InteropAppTests
//
//  Created by Bugen Zhao on 6/23/21.
//

import XCTest

class TestLifetime {
    let sema: DispatchSemaphore
    init(_ sema: DispatchSemaphore) {
        self.sema = sema
        print("swift: start of test lifetime")
    }

    deinit {
        print("swift: end of test lifetime")
    }

    func completed(_ success: Bool) {
        print("swift: the async operation has completed with result \(success)")
        sema.signal()
    }
}

class RustCallTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRustCallAsync() throws {
        let sema = DispatchSemaphore(value: 0)
        let test = TestLifetime(sema)
        let req = Request.with { $0.asyncBacktrace = BacktraceRequest() }
        rustCallAsync(req) { (res: BacktraceResponse) in
            test.completed(true)
        }
        sema.wait()
    }

}
