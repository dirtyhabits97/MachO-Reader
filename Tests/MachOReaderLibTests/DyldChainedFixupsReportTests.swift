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
            report = try DyldChainedFixupsReport(file: MachOFile(from: url(for: "helloworld")!, arch: nil)),
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

    func test_pagesContainBindOrRebaseEntries() {
        // Walking the chains must yield fixup entries; with the wrong stride the
        // chain mis-walks and terminates early (often with zero entries).
        let totalEntries = report.pageInfo().reduce(0) { acc, pages in
            acc + pages.pages.reduce(0) { $0 + $1.bindOrRebase.count }
        }
        XCTAssertGreaterThan(totalEntries, 0)
    }

    func test_throwsWhenBinaryHasNoChainedFixups() throws {
        // /bin/ls uses the older dyld-info / rebase-opcode style, so its x86_64
        // slice has no LC_DYLD_CHAINED_FIXUPS command. Building the report must
        // throw gracefully rather than crash with a fatalError.
        // Fail loudly if the fixture is missing — otherwise moving/removing it
        // would silently skip this test and let the crash regress unnoticed.
        let url = try XCTUnwrap(url(for: "ls"), "Missing 'ls' fixture")

        let file = try MachOFile(from: url, arch: "x86_64")
        XCTAssertThrowsError(try DyldChainedFixupsReport(file: file)) { error in
            XCTAssertEqual(error as? MachOFileError, .missingDyldChainedFixups)
        }
    }

    func test_fixtureUsesGeneric64OffsetFormat() {
        // The helloworld fixture is a plain arm64 binary, so its chained fixups use
        // the generic 64-bit offset format (4-byte stride) and decode to the
        // bind64 / rebase64 variants.
        let segmentsWithStarts = report.segmentInfo.compactMap(\.startsInSegment)
        XCTAssertNotEmpty(segmentsWithStarts)
        for startsInSegment in segmentsWithStarts {
            XCTAssertEqual(startsInSegment.pointerFormat, .DYLD_CHAINED_PTR_64_OFFSET)
        }

        for pages in report.pageInfo() {
            for page in pages.pages {
                for entry in page.bindOrRebase {
                    switch entry.underlyingValue {
                    case .bind64, .rebase64:
                        break // expected for this fixture
                    default:
                        XCTFail("Unexpected underlying value for a generic 64-bit binary")
                    }
                }
            }
        }
    }
}

func XCTAssertNotEmpty(_ col: some Collection) {
    XCTAssertNotEqual(col.count, 0)
}
