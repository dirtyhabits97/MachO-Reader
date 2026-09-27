import Foundation
import MachO
@testable import MachOReaderLib
import XCTest

/// Ground truth for the `ls` fixture's x86_64 slice, captured via
/// `xcrun dyld_info -fixups -arch x86_64 ls` (its x86_64 slice uses the
/// classic LC_DYLD_INFO_ONLY format, unlike its arm64e slice which uses
/// chained fixups).
final class DyldInfoReportTests: XCTestCase {

    // MARK: - Properties

    var report: DyldInfoReport!

    // MARK: - Set up

    override func setUpWithError() throws {
        try super.setUpWithError()

        let url = try XCTUnwrap(url(for: "ls"), "Missing 'ls' fixture")
        report = try DyldInfoReport(file: MachOFile(from: url, arch: "x86_64"))
    }

    // MARK: - Fixture Tests

    func test_rebaseCount_whenLsFixture() {
        XCTAssertEqual(report.rebases.count, 107)
    }

    func test_firstRebase_whenLsFixture() throws {
        let rebase = try XCTUnwrap(report.rebases.first)
        XCTAssertEqual(rebase.segmentName, "__DATA")
        XCTAssertEqual(rebase.sectionName, "__const")
        XCTAssertEqual(rebase.address, 0x1_0000_5040)
        XCTAssertEqual(rebase.type, .pointer)
    }

    func test_bindCount_whenLsFixture() {
        XCTAssertEqual(report.binds.count, 7)
    }

    func test_firstBind_whenLsFixture() throws {
        let bind = try XCTUnwrap(report.binds.first)
        XCTAssertEqual(bind.kind, .bind)
        XCTAssertEqual(bind.segmentName, "__DATA")
        XCTAssertEqual(bind.sectionName, "__got")
        XCTAssertEqual(bind.address, 0x1_0000_5000)
        XCTAssertEqual(bind.type, .pointer)
        XCTAssertEqual(bind.dylibName, "libSystem.B.dylib")
        XCTAssertEqual(bind.symbolName, "__DefaultRuneLocale")
        XCTAssertEqual(bind.addend, 0)
        XCTAssertFalse(bind.isWeakImport)
    }

    func test_weakBinds_whenLsFixture() {
        XCTAssertEqual(report.weakBinds.count, 0)
    }

    func test_lazyBindCount_whenLsFixture() {
        XCTAssertEqual(report.lazyBinds.count, 84)
    }

    func test_firstAndLastLazyBind_whenLsFixture() throws {
        let first = try XCTUnwrap(report.lazyBinds.first)
        XCTAssertEqual(first.symbolName, "___assert_rtn")
        XCTAssertEqual(first.address, 0x1_0000_52A8)

        let last = try XCTUnwrap(report.lazyBinds.last)
        XCTAssertEqual(last.symbolName, "_write")
        XCTAssertEqual(last.address, 0x1_0000_5540)
    }

    func test_weakImportLazyBind_whenLsFixture() throws {
        let strtonum = try XCTUnwrap(report.lazyBinds.first { $0.symbolName == "_strtonum" })
        XCTAssertTrue(strtonum.isWeakImport)
    }

    func test_throwsWhenBinaryHasNoDyldInfo() throws {
        // The helloworld fixture uses LC_DYLD_CHAINED_FIXUPS, not the classic
        // LC_DYLD_INFO/LC_DYLD_INFO_ONLY format, so building the report must
        // throw gracefully rather than crash.
        let url = try XCTUnwrap(url(for: "helloworld"))
        let file = try MachOFile(from: url, arch: nil)

        XCTAssertThrowsError(try DyldInfoReport(file: file)) { error in
            XCTAssertEqual(error as? MachOFileError, .missingDyldInfo)
        }
    }
}

// MARK: - Hand-built opcode stream tests

final class DyldOpcodeStreamParserTests: XCTestCase {

    // MARK: - Rebase opcodes

    func test_rebase_doRebaseUlebTimesSkippingUleb() throws {
        let segment = try makeSegment(segname: "__DATA", vmaddr: 0x1000, sections: [
            (sectname: "__data", addr: 0x1000, size: 0x100),
        ])

        // SET_TYPE_IMM(pointer), SET_SEGMENT_AND_OFFSET_ULEB(seg:0, off:8),
        // DO_REBASE_ULEB_TIMES_SKIPPING_ULEB(count:3, skip:8), DONE
        let bytes: [UInt8] = [0x11, 0x20, 0x08, 0x80, 0x03, 0x08, 0x00]

        var parser = RebaseOpcodeStreamParser(segments: [segment])
        let entries = try parser.parse(BinaryDecoder(data: Data(bytes)))

        XCTAssertEqual(entries.map(\.address), [0x1008, 0x1018, 0x1028])
        XCTAssertTrue(entries.allSatisfy { $0.type == .pointer })
        XCTAssertTrue(entries.allSatisfy { $0.sectionName == "__data" })
    }

    func test_rebase_truncatedStreamThrows() {
        // SET_SEGMENT_AND_OFFSET_ULEB with no following ULEB byte.
        let bytes: [UInt8] = [0x20]
        var parser = RebaseOpcodeStreamParser(segments: [])

        XCTAssertThrowsError(
            try parser.parse(BinaryDecoder(data: Data(bytes))),
        ) { error in
            XCTAssertTrue(error is BinaryDecodingError)
        }
    }

    // MARK: - Bind opcodes

    func test_bind_ordinalSymbolAddendAndDoBind() throws {
        let segment = try makeSegment(segname: "__DATA", vmaddr: 0x2000, sections: [
            (sectname: "__got", addr: 0x2000, size: 0x100),
        ])
        let dylib = try makeDylib(name: "/usr/lib/libFoo.dylib")

        // SET_DYLIB_ORDINAL_IMM(1), SET_SYMBOL_TRAILING_FLAGS_IMM(0, "hello"),
        // SET_SEGMENT_AND_OFFSET_ULEB(seg:0, off:0x10), SET_ADDEND_SLEB(-8), DO_BIND
        let bytes: [UInt8] = [0x11, 0x40] + Array("hello".utf8) + [0x00, 0x70, 0x10, 0x60, 0x78, 0x90, 0x00]

        var parser = BindOpcodeStreamParser(segments: [segment], dylibCommands: [dylib], kind: .bind)
        let entries = try parser.parse(BinaryDecoder(data: Data(bytes)))

        let bind = try XCTUnwrap(entries.first)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(bind.kind, .bind)
        XCTAssertEqual(bind.dylibOrdinal, 1)
        XCTAssertEqual(bind.dylibName, "libFoo.dylib")
        XCTAssertEqual(bind.symbolName, "hello")
        XCTAssertEqual(bind.addend, -8)
        XCTAssertEqual(bind.address, 0x2010)
        XCTAssertFalse(bind.isWeakImport)
    }

    func test_lazyBind_twoEntriesSeparatedByDone() throws {
        let segment = try makeSegment(segname: "__DATA", vmaddr: 0x3000, sections: [])
        let dylib = try makeDylib(name: "/usr/lib/libFoo.dylib")

        func entryBytes(symbol: String, offset: UInt8) -> [UInt8] {
            [0x11, 0x40] + Array(symbol.utf8) + [0x00, 0x70, offset, 0x90, 0x00]
        }

        // Two DO_BIND entries, each terminated by DONE (which only separates
        // entries within the lazy-bind stream, rather than ending it).
        let bytes = entryBytes(symbol: "foo", offset: 0x10) + entryBytes(symbol: "bar", offset: 0x18)

        var parser = BindOpcodeStreamParser(segments: [segment], dylibCommands: [dylib], kind: .lazy)
        let entries = try parser.parse(BinaryDecoder(data: Data(bytes)))

        XCTAssertEqual(entries.map(\.symbolName), ["foo", "bar"])
        XCTAssertEqual(entries.map(\.address), [0x3010, 0x3018])
        XCTAssertTrue(entries.allSatisfy { $0.kind == .lazy })
    }

    func test_bind_truncatedStreamThrows() {
        // SET_SYMBOL_TRAILING_FLAGS_IMM with no null-terminated name following.
        let bytes: [UInt8] = [0x40]
        var parser = BindOpcodeStreamParser(segments: [], dylibCommands: [], kind: .bind)

        XCTAssertThrowsError(
            try parser.parse(BinaryDecoder(data: Data(bytes))),
        ) { error in
            XCTAssertTrue(error is BinaryDecodingError)
        }
    }

    func test_bind_threadedOpcodeThrows() {
        // BIND_OPCODE_THREADED (0xD0) is only used by old arm64e binaries and is unsupported.
        let bytes: [UInt8] = [0xD0]
        var parser = BindOpcodeStreamParser(segments: [], dylibCommands: [], kind: .bind)

        XCTAssertThrowsError(
            try parser.parse(BinaryDecoder(data: Data(bytes))),
        )
    }
}

// MARK: - Test helpers

/// Hand-builds a `SegmentCommand` (and its sections) from raw little-endian
/// bytes matching `segment_command_64`/`section_64`'s memory layout, so tests
/// can exercise the opcode parsers without a full Mach-O file on disk.
private func makeSegment(
    segname: String,
    vmaddr: UInt64,
    sections: [(sectname: String, addr: UInt64, size: UInt64)],
) throws -> SegmentCommand {
    var body = Data()
    body += packedString16(segname)
    body += packed(vmaddr) // vmaddr
    body += packed(UInt64(0)) // vmsize
    body += packed(UInt64(0)) // fileoff
    body += packed(UInt64(0)) // filesize
    body += packed(Int32(0)) // maxprot
    body += packed(Int32(0)) // initprot
    body += packed(UInt32(sections.count)) // nsects
    body += packed(UInt32(0)) // flags

    for section in sections {
        body += packedString16(section.sectname)
        body += packedString16(segname)
        body += packed(section.addr)
        body += packed(section.size)
        body += packed(UInt32(0)) // offset
        body += packed(UInt32(0)) // align
        body += packed(UInt32(0)) // reloff
        body += packed(UInt32(0)) // nreloc
        body += packed(UInt32(0)) // flags
        body += packed(UInt32(0)) // reserved1
        body += packed(UInt32(0)) // reserved2
        body += packed(UInt32(0)) // reserved3
    }

    var header = Data()
    header += packed(UInt32(LC_SEGMENT_64))
    header += packed(UInt32(8 + body.count))

    return try SegmentCommand(from: LoadCommand(from: header + body, isSwapped: false))
}

/// Hand-builds a `DylibCommand` from raw little-endian bytes matching
/// `dylib_command`'s memory layout.
private func makeDylib(name: String) throws -> DylibCommand {
    let nameBytes = Array(name.utf8) + [0]
    let nameOffset: UInt32 = 24

    var data = Data()
    data += packed(UInt32(LC_LOAD_DYLIB))
    data += packed(nameOffset + UInt32(nameBytes.count))
    data += packed(nameOffset) // dylib.name.offset
    data += packed(UInt32(0)) // dylib.timestamp
    data += packed(UInt32(0)) // dylib.current_version
    data += packed(UInt32(0)) // dylib.compatibility_version
    data += Data(nameBytes)

    return try DylibCommand(from: LoadCommand(from: data, isSwapped: false))
}

private func packedString16(_ string: String) -> Data {
    var bytes = Array(string.utf8.prefix(16))
    bytes += Array(repeating: UInt8(0), count: 16 - bytes.count)
    return Data(bytes)
}

private func packed(_ value: some FixedWidthInteger) -> Data {
    withUnsafeBytes(of: value.littleEndian) { Data($0) }
}
