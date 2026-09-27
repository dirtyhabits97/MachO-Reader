@testable import MachOReaderLib
import XCTest

final class SemanticVersionTests: XCTestCase {

    func test_decodesEightBitMinorAndPatch() {
        // 14.20.31 packed as xxxx.yy.zz
        let version = SemanticVersion(0x000E_141F)

        XCTAssertEqual(version.major, 14)
        XCTAssertEqual(version.minor, 20)
        XCTAssertEqual(version.patch, 31)
        XCTAssertEqual(version.description, "14.20.31")
    }
}
