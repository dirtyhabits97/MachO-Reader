// swiftlint:disable line_length

@testable import MachOReaderLib
import XCTest

// MACH_HEADER         magic: MH_MAGIC_64 (0xfeedfacf)   cputype: ARM64   filetype: MH_EXECUTE   ncmds: 27   sizeofcmds: 2024
//                     flags: 0x00200085

// LC_SEGMENT_64                 cmdsize: 72         segname: __PAGEZERO           file: 0x000000000-0x000000000   vm: 0x000000000-0x100000000   prot: 0/0
// LC_SEGMENT_64                 cmdsize: 552        segname: __TEXT               file: 0x000000000-0x000004000   vm: 0x100000000-0x100004000   prot: 5/5
// LC_SEGMENT_64                 cmdsize: 312        segname: __DATA_CONST         file: 0x000004000-0x000008000   vm: 0x100004000-0x100008000   prot: 3/3
// LC_SEGMENT_64                 cmdsize: 72         segname: __LINKEDIT           file: 0x000008000-0x000008af4   vm: 0x100008000-0x10000c000   prot: 1/1
// LC_DYLD_CHAINED_FIXUPS        cmdsize: 16         dataoff: 0x00008000 (32768)   datasize: 672
// LC_DYLD_EXPORTS_TRIE          cmdsize: 16         dataoff: 0x000082a0 (33440)   datasize: 48
// LC_SYMTAB                     cmdsize: 24         symoff: 33496   nsyms: 31   stroff: 34048   strsize: 1112
// LC_DYSYMTAB                   cmdsize: 80         nlocalsym: 13  nextdefsym: 2   nundefsym: 16   nindirectsyms: 14
// LC_LOAD_DYLINKER              cmdsize: 32         /usr/lib/dyld
// LC_UUID                       cmdsize: 24         7806C5DF-41F6-39CA-9DB5-F18DFB005EC0
// LC_BUILD_VERSION              cmdsize: 32         platform: macOS   minos: 12.0.0   sdk: 12.3.0
// LC_SOURCE_VERSION             cmdsize: 16         0.0.0.0.0
// LC_MAIN                       cmdsize: 24         entryoff: 0x000003db0 (15792)   stacksize: 0
// LC_LOAD_DYLIB                 cmdsize: 56         /usr/lib/libobjc.A.dylib
// LC_LOAD_DYLIB                 cmdsize: 56         /usr/lib/libSystem.B.dylib
// LC_LOAD_DYLIB                 cmdsize: 64         /usr/lib/swift/libswiftCore.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 72         /usr/lib/swift/libswiftCoreFoundation.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 72         /usr/lib/swift/libswiftCoreGraphics.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftDarwin.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftDispatch.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftFoundation.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftIOKit.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftObjectiveC.dylib
// LC_LOAD_WEAK_DYLIB            cmdsize: 64         /usr/lib/swift/libswiftXPC.dylib
// LC_FUNCTION_STARTS            cmdsize: 16         dataoff: 0x000082d0 (33488)   datasize: 8
// LC_DATA_IN_CODE               cmdsize: 16         dataoff: 0x000082d8 (33496)   datasize: 0
// LC_CODE_SIGNATURE             cmdsize: 16         dataoff: 0x00008960 (35168)   datasize: 404
final class MachOFileTests: XCTestCase {

    // MARK: - Properties

    var helloWorldURL: URL? { url(for: "helloworld") }

    // MARK: - Tests

    func test_hasCommands_whenValidBinary() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        XCTAssertFalse(file.commands.isEmpty)
    }

    func test_hasSegmentCommands() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let segmentCommands = file.commands.segmentCommands

        XCTAssertEqual(segmentCommands.count, 4)
        XCTAssertEqual(segmentCommands[0].segname, "__PAGEZERO")
        XCTAssertEqual(segmentCommands[1].segname, "__TEXT")
        XCTAssertEqual(segmentCommands[2].segname, "__DATA_CONST")
        XCTAssertEqual(segmentCommands[3].segname, "__LINKEDIT")
    }

    // Check the section's addr is within the segment's vm bounds
    func test_sectionWithinBoundsOfSectionVM() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let segmentCommands = file.commands.segmentCommands

        XCTAssertEqual(segmentCommands[1].segname, "__TEXT")
        let textSegment = segmentCommands[1]
        let lastSectionUpperBound = (textSegment.sections.last?.addr ?? 0) + (textSegment.sections.last?.size ?? 0)

        XCTAssertTrue(textSegment.vmaddr + textSegment.vmsize >= lastSectionUpperBound,
                      "Section's addr upper bound exceeds the Segment's bounds.")
    }

    func test_onlyOneUuidCommand() throws {
        try assertOneCommand(.uuid)
    }

    func test_onlyOneBuildVersionCommand() throws {
        try assertOneCommand(.buildVersion)
    }

    func test_onlyOneSourceVersionCommand() throws {
        try assertOneCommand(.sourceVersion)
    }

    func test_onlyOneMainCommand() throws {
        try assertOneCommand(.main)
    }
}

// MARK: - Helpers

extension MachOFileTests {

    func assertOneCommand(_ cmd: Cmd) throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let commands = file.commands.filter { $0.cmd == cmd }

        XCTAssertEqual(commands.count, 1,
                       "The binary MUST have only 1 \(cmd.readableValue ?? String(cmd.rawValue)).")
    }
}

// TODO: Consider creating a custom collection type for LoadCommands
// TODO: Consider moving this to the MachO_Reader target
extension Array where Element == LoadCommand {

    var segmentCommands: [SegmentCommand] {
        compactMap { command -> SegmentCommand? in
            if case let .segmentCommand(segmentCommand) = command.commandType() {
                return segmentCommand
            }
            return nil
        }
    }
}
