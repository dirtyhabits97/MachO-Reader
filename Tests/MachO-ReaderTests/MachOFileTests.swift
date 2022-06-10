@testable import MachO_Reader
import XCTest

final class MachOFileTests: XCTestCase {

    var helloWorldURL: URL? { url(for: "helloworld") }

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
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let uuidCommands = file.commands.uuidCommands

        XCTAssertEqual(uuidCommands.count, 1,
                       "The binary MUST have only 1 LC_UUID.")
    }

    func test_onlyOneBuildVersionCommand() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let buildVersionCommands = file.commands.buildVersionCommands

        XCTAssertEqual(buildVersionCommands.count, 1,
                       "The binary MUST have only 1 LC_BUILD_VERSION.")
    }

    func test_onlyOneSourceVersionCommand() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let sourceVersionCommands = file.commands.sourceVersionCommands

        XCTAssertEqual(sourceVersionCommands.count, 1,
                       "The binary MUST have only 1 LC_SOURCE_VERSION.")
    }

    func test_onlyOneMainCommand() throws {
        guard let url = helloWorldURL else { return }

        let file = try MachOFile(from: url, arch: nil)
        let entryPointCommand = file.commands.entryPointCommand

        XCTAssertEqual(entryPointCommand.count, 1,
                       "The binary MUST have only 1 LC_SOURCE_VERSION.")
    }
}

// TODO: Consider creating a custom collection type for LoadCommands
// TODO: Consider moving this to the MachO_Reader target
extension Array where Element == LoadCommand {

    var buildVersionCommands: [BuildVersionCommand] {
        compactMap { command -> BuildVersionCommand? in
            if case let .buildVersionCommand(buildVersionCommand) = command.commandType() {
                return buildVersionCommand
            }
            return nil
        }
    }

    var entryPointCommand: [EntryPointCommand] {
        compactMap { command -> EntryPointCommand? in
            if case let .entryPointCommand(entryPointCommand) = command.commandType() {
                return entryPointCommand
            }
            return nil
        }
    }

    var segmentCommands: [SegmentCommand] {
        compactMap { command -> SegmentCommand? in
            if case let .segmentCommand(segmentCommand) = command.commandType() {
                return segmentCommand
            }
            return nil
        }
    }

    var sourceVersionCommands: [SourceVersionCommand] {
        compactMap { command -> SourceVersionCommand? in
            if case let .sourceVersionCommand(sourceVersionCommand) = command.commandType() {
                return sourceVersionCommand
            }
            return nil
        }
    }

    var uuidCommands: [UUIDCommand] {
        compactMap { command -> UUIDCommand? in
            if case let .uuidCommand(uuidCommand) = command.commandType() {
                return uuidCommand
            }
            return nil
        }
    }
}
