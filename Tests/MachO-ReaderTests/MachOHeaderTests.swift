@testable import MachO_Reader
import XCTest

final class MachOHeaderTests: XCTestCase {

    var helloWorldURL: URL? { url(for: "helloworld") }

    func test_defaultHeader_whenInvalidArch() throws {
        guard let url = helloWorldURL else { return }

        XCTAssertNoThrow(try MachOFile(from: url, arch: "invalid_arch"))
    }

    func test_oneHeader_whenOnlyOneArchIsSupported() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        XCTAssertEqual(file.header.cputype, .arm_64)
    }
}
