import Foundation
import MachO
@testable import MachOReaderLib
import XCTest

/// Ground truth for the `helloworld` fixture, captured via `dyld_info -exports`:
///
/// LC_DYLD_EXPORTS_TRIE   dataoff: 33440   datasize: 48
///
///   0x00000000  __mh_execute_header
///   0x00003DB0  _main
///
/// Ground truth for the `ls` fixture (fat, x86_64 + arm64e): both slices export
/// only `__mh_execute_header`, at offset 0.
final class ExportTrieReportTests: XCTestCase {

    // MARK: - Properties

    var report: ExportTrieReport!

    // MARK: - Set up

    override func setUpWithError() throws {
        try super.setUpWithError()

        let url = try XCTUnwrap(url(for: "helloworld"))
        report = try ExportTrieReport(file: MachOFile(from: url, arch: nil))
    }

    // MARK: - helloworld

    func test_exportCount_whenHelloworldFixture() {
        XCTAssertEqual(report.symbols.count, 2)
    }

    func test_symbolsAreSortedByName() {
        XCTAssertEqual(report.symbols.map(\.name), report.symbols.map(\.name).sorted())
    }

    func test_resolvesAddressAndKind_forMain() throws {
        let main = try XCTUnwrap(report.symbols.first { $0.name == "_main" })
        XCTAssertEqual(main.address, 0x3DB0)
        XCTAssertEqual(main.kind, .regular)
        XCTAssertFalse(main.isWeakDefinition)
        XCTAssertFalse(main.isReexport)
        XCTAssertFalse(main.isStubAndResolver)
    }

    func test_resolvesAddress_forMhExecuteHeader() throws {
        let header = try XCTUnwrap(report.symbols.first { $0.name == "__mh_execute_header" })
        XCTAssertEqual(header.address, 0)
        XCTAssertEqual(header.kind, .regular)
    }

    // MARK: - ls (fat binary)

    func test_exports_whenLsFixture_x86_64() throws {
        let url = try XCTUnwrap(url(for: "ls"), "Missing 'ls' fixture")
        let file = try MachOFile(from: url, arch: "x86_64")

        let report = try ExportTrieReport(file: file)

        XCTAssertEqual(report.symbols.map(\.name), ["__mh_execute_header"])
        XCTAssertEqual(report.symbols.first?.address, 0)
    }

    func test_exports_whenLsFixture_arm64e() throws {
        let url = try XCTUnwrap(url(for: "ls"), "Missing 'ls' fixture")
        let file = try MachOFile(from: url, arch: "arm64e")

        let report = try ExportTrieReport(file: file)

        XCTAssertEqual(report.symbols.map(\.name), ["__mh_execute_header"])
    }

    // MARK: - Missing export trie

    func test_throwsMissingExportTrie_whenNoTrieOrDyldInfoCommand() throws {
        let file = try MachOFile(from: emptyMachOData(), arch: nil)

        XCTAssertThrowsError(try ExportTrieReport(file: file)) { error in
            XCTAssertEqual(error as? MachOFileError, .missingExportTrie)
        }
    }
}

// MARK: - Hand-built trie tests

/// Builds and walks small, hand-assembled export tries so branches that are
/// rare (or absent) in organically-linked fixture binaries — re-exports,
/// corrupt offsets, cycles — are exercised directly.
final class ExportTrieBuilderTests: XCTestCase {

    func test_walksRegularAndReexportNodes() throws {
        // Root -> "_regular" (terminal: regular export, address 0x1234)
        //      -> "_reexport" (terminal: reexport, ordinal 2, name "_imported_c")
        let data = TrieBuilder.root(children: [
            ("_regular", TrieBuilder.terminal(flags: 0x00, payload: uleb128(0x1234))),
            ("_reexport", TrieBuilder.terminal(flags: 0x08, payload: uleb128(2) + cString("_imported_c"))),
        ])

        let symbols = try ExportTrieBuilder(decoder: BinaryDecoder(data: data), trieSize: data.count).symbols
            .sorted { $0.name < $1.name }

        XCTAssertEqual(symbols.count, 2)

        let regular = try XCTUnwrap(symbols.first { $0.name == "_regular" })
        XCTAssertEqual(regular.address, 0x1234)
        XCTAssertEqual(regular.kind, .regular)
        XCTAssertFalse(regular.isReexport)

        let reexport = try XCTUnwrap(symbols.first { $0.name == "_reexport" })
        XCTAssertTrue(reexport.isReexport)
        XCTAssertEqual(reexport.reexportOrdinal, 2)
        XCTAssertEqual(reexport.reexportName, "_imported_c")
        XCTAssertNil(reexport.address)
    }

    func test_emptyImportedName_reportsNilReexportName() throws {
        // An empty imported name in the trie means "same name as the export".
        let data = TrieBuilder.root(children: [
            ("_same_name", TrieBuilder.terminal(flags: 0x08, payload: uleb128(1) + cString(""))),
        ])

        let symbols = try ExportTrieBuilder(decoder: BinaryDecoder(data: data), trieSize: data.count).symbols

        let reexport = try XCTUnwrap(symbols.first)
        XCTAssertEqual(reexport.reexportOrdinal, 1)
        XCTAssertNil(reexport.reexportName)
    }

    func test_throws_whenChildOffsetPointsPastTheEnd() {
        let data = TrieBuilder.root(children: [("_x", offset: 9999)])

        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try ExportTrieBuilder(decoder: decoder, trieSize: data.count).symbols) { error in
            XCTAssertTrue(error is BinaryDecodingError, "Expected a BinaryDecodingError, got \(error)")
        }
    }

    func test_throws_whenTrieHasACycle() {
        // A single child edge pointing back at the root itself (offset 0).
        let data = TrieBuilder.root(children: [("_cycle", offset: 0)])

        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try ExportTrieBuilder(decoder: decoder, trieSize: data.count).symbols) { error in
            XCTAssertEqual(error as? ExportTrieError, .cycleDetected(offset: 0))
        }
    }
}

// MARK: - TrieBuilder

/// Assembles minimal export tries by hand: a single non-terminal root node
/// whose children are either terminal nodes (serialized right after the
/// root) or an explicit, possibly out-of-range, byte offset.
private enum TrieBuilder {

    /// A terminal node's bytes: ULEB128 `terminalSize`, the payload itself,
    /// then a zero `childCount` byte (terminal nodes have no children here).
    static func terminal(flags: UInt64, payload: [UInt8]) -> [UInt8] {
        let terminalPayload = uleb128(flags) + payload
        return uleb128(UInt64(terminalPayload.count)) + terminalPayload + [0]
    }

    /// A root node (non-terminal: `terminalSize == 0`) with `children.count`
    /// children, each serialized as its own terminal node placed right after
    /// the root's header. Assumes every child offset encodes as a single
    /// ULEB128 byte (true for the small fixtures these tests build) — sizing
    /// is asserted below rather than assumed silently.
    static func root(children: [(label: String, node: [UInt8])]) -> Data {
        let labels = children.map { cString($0.label) }
        let headerSize = 2 + labels.reduce(0) { $0 + $1.count + 1 }

        var header: [UInt8] = [0x00, UInt8(children.count)]
        var body: [UInt8] = []

        for (label, (_, node)) in zip(labels, children) {
            let childOffset = uleb128(UInt64(headerSize + body.count))
            precondition(childOffset.count == 1, "fixture child offset grew past a single ULEB128 byte")

            header += label
            header += childOffset
            body += node
        }

        return Data(header + body)
    }

    /// A root node with a single child whose offset is given explicitly
    /// (rather than a serialized node), to test out-of-range/cyclic offsets.
    static func root(children: [(label: String, offset: Int)]) -> Data {
        var header: [UInt8] = [0x00, UInt8(children.count)]
        for (label, offset) in children {
            header += cString(label)
            header += uleb128(UInt64(offset))
        }
        return Data(header)
    }
}

// MARK: - LEB128 / C string helpers

private func uleb128(_ value: UInt64) -> [UInt8] {
    var value = value
    var bytes: [UInt8] = []
    repeat {
        var byte = UInt8(value & 0x7F)
        value >>= 7
        if value != 0 {
            byte |= 0x80
        }
        bytes.append(byte)
    } while value != 0
    return bytes
}

private func cString(_ string: String) -> [UInt8] {
    Array(string.utf8) + [0]
}

// MARK: - Synthetic empty Mach-O

/// A minimal, valid `mach_header_64` with zero load commands — no
/// `LC_DYLD_EXPORTS_TRIE` and no `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY`.
private func emptyMachOData() -> Data {
    var header = mach_header_64()
    header.magic = UInt32(MH_MAGIC_64)
    header.cputype = CPU_TYPE_ARM64
    header.cpusubtype = CPU_SUBTYPE_ARM64_ALL
    header.filetype = UInt32(MH_EXECUTE)
    header.ncmds = 0
    header.sizeofcmds = 0
    header.flags = 0
    header.reserved = 0

    return withUnsafeBytes(of: header) { Data($0) }
}
