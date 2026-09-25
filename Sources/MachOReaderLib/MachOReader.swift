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

    public func getBuildVersionCommand() throws -> BuildVersionCommand? {
        for loadCommand in file.commands {
            if case let .buildVersionCommand(buildVersionCommand) = try loadCommand.commandType() {
                return buildVersionCommand
            }
        }
        return nil
    }

    public func getDylibCommands() throws -> [DylibCommand] {
        try file.commands
            .compactMap { (loadCommand: LoadCommand) -> DylibCommand? in
                guard case let .dylibCommand(dylibCommand) = try loadCommand.commandType() else { return nil }
                return dylibCommand
            }
    }

    public func getSegmentCommands() throws -> [SegmentCommand] {
        try file.commands
            .compactMap { (loadCommand: LoadCommand) -> SegmentCommand? in
                guard case let .segmentCommand(segmentCommand) = try loadCommand.commandType() else { return nil }
                return segmentCommand
            }
    }

    public func getSymbolTableReport() throws -> SymbolTableReport {
        try file.symbolTableReport()
    }

    // TODO: Add tests to this
    public func getLoadCommands(_ cmd: String) -> [LoadCommand] {
        file.commands.filter { (loadCommand: LoadCommand) in
            loadCommand.cmd.readableValue == cmd
        }
    }
}
