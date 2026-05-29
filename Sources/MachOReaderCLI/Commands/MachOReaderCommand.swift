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

    @Option(name: .customShort("c"), help: "The load command LC_* to inspect")
    var loadCommandToInspect: String?

    @Flag(help: "Only outputs information for dylib-related commands.")
    var dylibs: Bool = false

    @Flag(name: .shortAndLong, help: "Only outputs information for the fat header.")
    var fatHeader: Bool = false

    @Flag(name: .shortAndLong, help: "Only outputs information for the mach-o header.")
    var header: Bool = false

    @Flag(help: "Only outputs information for the segment commands.")
    var segments: Bool = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        let expandedPath = (pathToBinary as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        let reader = try MachOReader(binaryURL: url, arch: arch)

        switch format {
        case .text:
            printText(reader: reader)
        case .json:
            printJSON(reader: reader)
        }
    }

    // MARK: - Text Output

    private func printText(reader: MachOReader) {
        let formatter = TextFormatter()

        // loadCommand takes higher priority than the rest
        if let loadCommandToInspect {
            for loadCommand in reader.getLoadCommands(loadCommandToInspect) {
                print(formatter.formatDetailed(loadCommand.commandType()))
            }
            return
        }

        // print the FAT header if specified and it exists in the binary
        if fatHeader, let fatHeader = reader.getFatHeader() {
            print(formatter.format(fatHeader))
            return
        }

        // print the header for a given architecture
        if header {
            print(formatter.format(reader.getHeader()))
            return
        }

        // print the build version if it exists
        if buildVersion, let command = reader.getBuildVersionCommand() {
            print(formatter.formatDetailed(command))
            return
        }

        // only print dylibs
        if dylibs {
            for command in reader.getDylibCommands() {
                print(formatter.formatDetailed(command))
            }
            return
        }

        // only print segments
        if segments {
            for command in reader.getSegmentCommands() {
                print(formatter.formatDetailed(command))
            }
            return
        }

        // print default information
        print(formatter.format(reader.getParsedFile()))
    }

    // MARK: - JSON Output

    private func printJSON(reader: MachOReader) {
        let formatter = JSONFormatter()

        // loadCommand takes higher priority than the rest
        if let loadCommandToInspect {
            let commands = reader.getLoadCommands(loadCommandToInspect).map {
                formatter.format($0.commandType())
            }
            print(formatter.toJSONString(commands))
            return
        }

        // print the FAT header if specified and it exists in the binary
        if fatHeader, let fatHeader = reader.getFatHeader() {
            print(formatter.toJSONString(formatter.format(fatHeader)))
            return
        }

        // print the header for a given architecture
        if header {
            print(formatter.toJSONString(formatter.format(reader.getHeader())))
            return
        }

        // print the build version if it exists
        if buildVersion, let command = reader.getBuildVersionCommand() {
            print(formatter.toJSONString(formatter.format(command)))
            return
        }

        // only print dylibs
        if dylibs {
            let commands = reader.getDylibCommands().map { formatter.format($0) }
            print(formatter.toJSONString(commands))
            return
        }

        // only print segments
        if segments {
            let commands = reader.getSegmentCommands().map { formatter.format($0) }
            print(formatter.toJSONString(commands))
            return
        }

        // print default information
        print(formatter.toJSONString(formatter.format(reader.getParsedFile())))
    }
}
