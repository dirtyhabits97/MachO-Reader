import Foundation
@testable import MachOReaderLib
import XCTest

/// Ground truth for the `helloworld` fixture, captured via `nm -m` / `otool -l`.
/// (Mirrors the otool dump convention atop MachOFileTests.swift.)
///
/// LC_SYMTAB     nsyms: 31    symoff: 33496   stroff: 34048   strsize: 1112
/// LC_DYSYMTAB   nlocalsym: 13   nextdefsym: 2   nundefsym: 16   (13 + 2 + 16 == 31)
///
/// Defined external (N_SECT | N_EXT) — exactly 2:
///   0x100000000  T  __mh_execute_header
///   0x100003db0  T  _main
/// Undefined external (N_UNDF | N_EXT) — 16, e.g.:
///   U  _swift_bridgeObjectRetain   (from libswiftCore)
/// Local (N_SECT / not external) — 13, e.g.:
///   0x100003e80  t  _$ss27_finalizeUninitializedArrayySayxGABnlF
final class SymbolTableReportTests: XCTestCase {

    // MARK: - Properties

    var report: SymbolTableReport!

    // MARK: - Set up

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Fail loudly if the fixture is missing rather than silently skipping.
        let url = try XCTUnwrap(url(for: "helloworld"))
        report = try SymbolTableReport(file: MachOFile(from: url, arch: nil))
    }

    // MARK: - Tests

    func test_symbolCount_whenHelloworldFixture() {
        XCTAssertEqual(report.symbols.count, 31)
    }

    func test_undefinedExternalCount_matchesDysymtab() {
        let undefinedExternal = report.symbols.filter { $0.type == .undefined && $0.isExternal }
        XCTAssertEqual(undefinedExternal.count, 16, "Should match LC_DYSYMTAB.nundefsym")
    }

    func test_definedExternalCount_matchesDysymtab() {
        let definedExternal = report.symbols.filter { $0.type == .section && $0.isExternal }
        XCTAssertEqual(definedExternal.count, 2, "Should match LC_DYSYMTAB.nextdefsym")

        let names = Set(definedExternal.compactMap(\.name))
        XCTAssertEqual(names, ["_main", "__mh_execute_header"])
    }

    func test_localCount_matchesDysymtab() {
        let local = report.symbols.filter { !$0.isExternal && !$0.isStab }
        XCTAssertEqual(local.count, 13, "Should match LC_DYSYMTAB.nlocalsym")
    }

    func test_resolvesNameAndValue_forMain() throws {
        let main = try XCTUnwrap(report.symbols.first { $0.name == "_main" })
        XCTAssertEqual(main.type, .section)
        XCTAssertTrue(main.isExternal)
        XCTAssertEqual(main.value, 0x1_0000_3DB0)
    }

    func test_resolvesName_forUndefinedImport() throws {
        let symbol = try XCTUnwrap(report.symbols.first { $0.name == "_swift_bridgeObjectRetain" })
        XCTAssertEqual(symbol.type, .undefined)
        XCTAssertTrue(symbol.isExternal)
        XCTAssertEqual(symbol.value, 0)
    }

    func test_readableType_forMain_containsExtAndSect() throws {
        let main = try XCTUnwrap(report.symbols.first { $0.name == "_main" })
        XCTAssertTrue(main.readableType.contains("N_EXT"))
        XCTAssertTrue(main.readableType.contains("N_SECT"))
    }
}
