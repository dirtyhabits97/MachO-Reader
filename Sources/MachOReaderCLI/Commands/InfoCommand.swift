import ArgumentParser
import Foundation
import MachOReaderLib

struct InfoCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "info",
                                                    abstract: "Inspect the header and load commands of a binary.")

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

        let file = try MachOFile(from: url, arch: arch)

        switch format {
        case .text:
            printText(file: file)
        case .json:
            printJSON(file: file)
        }
    }

    // MARK: - Text Output

    private func printText(file: MachOFile) {
        let formatter = TextFormatter()

        // loadCommand takes higher priority than the rest
        if let loadCommandToInspect {
            for loadCommand in file.commands.getLoadCommands(loadCommandToInspect) {
                print(formatter.formatDetailed(loadCommand.commandType()))
            }
            return
        }

        // print the FAT header if specified and it exists in the binary
        if fatHeader, let fatHeader = file.fatHeader {
            print(formatter.format(fatHeader))
            return
        }

        // print the header for a given architecture
        if header {
            print(formatter.format(file.header))
            return
        }

        // print the build version if it exists
        if buildVersion, let command = file.commands.getBuildVersionCommand() {
            print(formatter.formatDetailed(command))
            return
        }

        // only print dylibs
        if dylibs {
            for command in file.commands.getDylibCommands() {
                print(formatter.formatDetailed(command))
            }
            return
        }

        // only print segments
        if segments {
            for command in file.commands.getSegmentCommands() {
                print(formatter.formatDetailed(command))
            }
            return
        }

        // print default information
        print(formatter.format(file))
    }

    // MARK: - JSON Output

    private func printJSON(file: MachOFile) {
        let formatter = JSONFormatter()

        // loadCommand takes higher priority than the rest
        if let loadCommandToInspect {
            let commands = file.commands.getLoadCommands(loadCommandToInspect).map {
                formatter.format($0.commandType())
            }
            print(formatter.toJSONString(commands))
            return
        }

        // print the FAT header if specified and it exists in the binary
        if fatHeader, let fatHeader = file.fatHeader {
            print(formatter.toJSONString(formatter.format(fatHeader)))
            return
        }

        // print the header for a given architecture
        if header {
            print(formatter.toJSONString(formatter.format(file.header)))
            return
        }

        // print the build version if it exists
        if buildVersion, let command = file.commands.getBuildVersionCommand() {
            print(formatter.toJSONString(formatter.format(command)))
            return
        }

        // only print dylibs
        if dylibs {
            let commands = file.commands.getDylibCommands().map { formatter.format($0) }
            print(formatter.toJSONString(commands))
            return
        }

        // only print segments
        if segments {
            let commands = file.commands.getSegmentCommands().map { formatter.format($0) }
            print(formatter.toJSONString(commands))
            return
        }

        // print default information
        print(formatter.toJSONString(formatter.format(file)))
    }
}
