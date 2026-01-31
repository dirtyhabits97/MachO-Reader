@testable import Env
import Foundation
import XCTest

final class EnvTests: XCTestCase {

    private var processInfo = TestProcessInfo()
    private var env = Env()

    func testReadEnvVars() {
        // given
        XCTAssertNil(env.FOO)
        XCTAssertNil(env.BAR)

        // when
        processInfo.testEnvironment["FOO"] = "FOO"
        processInfo.testEnvironment["BAR"] = "BAR"

        // then
        XCTAssertEqual(env.FOO, "FOO")
        XCTAssertEqual(env.BAR, "BAR")
    }

    override func setUp() {
        super.setUp()
        processInfo = TestProcessInfo()
        env = Env(processInfo: processInfo)
    }
}

private class TestProcessInfo: ProcessInfo {

    var testEnvironment = [String: String]()

    override var environment: [String: String] {
        testEnvironment
    }
}
