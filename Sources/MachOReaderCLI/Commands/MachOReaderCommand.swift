import ArgumentParser
import Foundation
import MachOReaderLib

@main
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

        let reader = try MachOReader(binaryURL: url, arch: arch)
        // print the FAT header if specified and it exists in the binary
        if fatHeader, let fatHeader = reader.getFatHeader() {
            return CLIFormatter.print(fatHeader)
        }
        // print the header for a given architecture
        if header {
            return CLIFormatter.print(reader.getHeader())
        }
        // print the build version if it exists
        if buildVersion, let command = reader.getBuildVersionCommand() {
            return CLIFormatter.print(command)
        }
        // only print dylibs
        if dylibs {
            return reader.getDylibCommands().forEach(CLIFormatter.print(_:))
        }
        // only print segments
        if segments {
            return reader.getDylibCommands().forEach(CLIFormatter.print(_:))
        }
        // print default information
        CLIFormatter.print(reader.getParsedFile())
    }
}
