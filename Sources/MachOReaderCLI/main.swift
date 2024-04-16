import ArgumentParser
import Foundation
import MachOReaderLib

struct MachOReaderCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "read",
                                                    subcommands: [DyldChainedFixupsCommand.self])

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs information for LC_BUILD_VERSION.")
    var buildVersion: Bool = false

    @Flag(help: "Only outputs information for dylib-related commands.")
    var dylibs: Bool = false

    @Flag(name: .shortAndLong, help: "Only outputs information for the fat header.")
    var fatHeader: Bool = false

    @Flag(name: .shortAndLong, help: "Only outputs information for the mach-o header.")
    var header: Bool = false

    @Flag(help: "Only outputs information for the segment commands.")
    var segments: Bool = false

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        guard
            let url = URL(string: "file://\(pathToBinary)")
        else {
            fatalError("Could not create url for \(pathToBinary)")
        }

        let file = try MachOFile(from: url, arch: arch)
        // only print fat header
        if fatHeader, let header = file.fatHeader {
            CLIFormatter.print(header)
            return
        }
        // only print mach-o header
        if header {
            CLIFormatter.print(file.header)
            return
        }
        // onlyl prints build version
        if buildVersion {
            file.commands
                .lazy
                .compactMap { (loadCommand: LoadCommand) -> BuildVersionCommand? in
                    if case let .buildVersionCommand(buildVersionCommand) = loadCommand.commandType() {
                        return buildVersionCommand
                    }
                    return nil
                }
                .first
                .map { CLIFormatter.print($0) }
            return
        }
        // only print dylibs
        if dylibs {
            file.commands
                .compactMap { (loadCommand: LoadCommand) -> DylibCommand? in
                    guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
                    return dylibCommand
                }
                .forEach { CLIFormatter.print($0) }
            return
        }
        // only print segments
        if segments {
            file.commands
                .compactMap { (loadCommand: LoadCommand) -> SegmentCommand? in
                    guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
                    return segmentCommand
                }
                .forEach { CLIFormatter.print($0) }
            return
        }
        // print default information
        CLIFormatter.print(file)
    }
}

MachOReaderCommand.main()
