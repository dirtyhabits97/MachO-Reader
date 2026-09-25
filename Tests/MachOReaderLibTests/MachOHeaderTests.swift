@testable import MachOReaderLib
import XCTest

final class MachOHeaderTests: XCTestCase {

    var helloWorldURL: URL? {
        url(for: "helloworld")
    }

    func test_throws_whenUnknownArch() throws {
        guard let url = helloWorldURL else { return }

        XCTAssertThrowsError(try MachOFile(from: url, arch: "invalid_arch")) { error in
            XCTAssertEqual(error as? MachOFileError, .unknownArch("invalid_arch"))
        }
    }

    func test_oneHeader_whenOnlyOneArchIsSupported() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        XCTAssertEqual(file.header.cputype, .arm64)
    }
}
