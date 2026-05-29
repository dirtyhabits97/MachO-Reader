import Foundation

public final class MachOReader {

    private let file: MachOFile

    public init(binaryURL: URL, arch: String?) throws {
        file = try MachOFile(from: binaryURL, arch: arch)
    }

    public func getParsedFile() -> MachOFile {
        file
    }

    public func getFatHeader() -> MachOFatHeader? {
        file.fatHeader
    }

    public func getHeader() -> MachOHeader {
        file.header
    }

    public func getBuildVersionCommand() -> BuildVersionCommand? {
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

    public func getDylibCommands() -> [DylibCommand] {
        file.commands
            .compactMap { (loadCommand: LoadCommand) -> DylibCommand? in
                guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
                return dylibCommand
            }
    }

    public func getSegmentCommands() -> [SegmentCommand] {
        file.commands
            .compactMap { (loadCommand: LoadCommand) -> SegmentCommand? in
                guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
                return segmentCommand
            }
    }

    // TODO: Add tests to this
    public func getLoadCommands(_ cmd: String) -> [LoadCommand] {
        file.commands.filter { (loadCommand: LoadCommand) in
            loadCommand.cmd.readableValue == cmd
        }
    }
}
