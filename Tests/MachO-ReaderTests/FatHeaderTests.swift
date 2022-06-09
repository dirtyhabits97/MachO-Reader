import XCTest
import class Foundation.Bundle
@testable import MachO_Reader

final class FatHeaderTests: XCTestCase {

    func test_noFatHeader_whenOnlyOneArchIsSupported() throws {
        guard let url = url(for: "helloworld") else { return  }

        let file = try MachOFile(from: url, arch: nil)
        XCTAssertNil(file.fatHeader, "Binary with 1 arch should not have a fat header.")
    }
}
