import Foundation
import MachOReaderLib

final class MachOReader {

    private let file: MachOFile

    init(binaryURL: URL, arch: String?) throws {
        file = try MachOFile(from: binaryURL, arch: arch)
    }

    func getParsedFile() -> MachOFile {
        file
    }

    func getFatHeader() -> MachOFatHeader? {
        file.fatHeader
    }

    func getHeader() -> MachOHeader {
        file.header
    }

    func getBuildVersionCommand() -> BuildVersionCommand? {
        file.commands
            .lazy
            .compactMap { (loadCommand: LoadCommand) -> BuildVersionCommand? in
                if case let .buildVersionCommand(buildVersionCommand) = loadCommand.commandType() {
                    return buildVersionCommand
                }
                return nil
            }
            .first
    }

    func getDylibCommands() -> [DylibCommand] {
        file.commands
            .compactMap { (loadCommand: LoadCommand) -> DylibCommand? in
                guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
                return dylibCommand
            }
    }

    func getSegmentCommands() -> [SegmentCommand] {
        file.commands
            .compactMap { (loadCommand: LoadCommand) -> SegmentCommand? in
                guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
                return segmentCommand
            }
    }
}
