import Foundation
@testable import MachOReaderLib
import XCTest

final class DyldChainedFixupsReportTests: XCTestCase {

    // MARK: - Properties

    var report: DyldChainedFixupsReport!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        XCTAssertNoThrow(
            report = try DyldChainedFixupsReport(file: MachOFile(from: url(for: "helloworld")!, arch: nil))
        )
    }

    // MARK: - Tests

    func test_hasImports() {
        XCTAssertNotEmpty(report.imports)
    }

    func test_hasSegmentInfo() {
        XCTAssertNotEmpty(report.segmentInfo)
    }

    func test_matchesPagesWithSegmentInfo() {
        let pageInfo = report.pageInfo()
        XCTAssertEqual(report.segmentInfo.count, pageInfo.count)

        for (segmentInfo, pageInfo) in zip(report.segmentInfo, report.pageInfo()) {
            XCTAssertEqual(segmentInfo.hasPages, pageInfo.pages.count > 0)
        }
    }
}

func XCTAssertNotEmpty<C: Collection>(_ col: C) {
    XCTAssertNotEqual(col.count, 0)
}
