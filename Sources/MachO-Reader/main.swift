import ArgumentParser
import Foundation

struct Reader: ParsableCommand {

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

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
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
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
        // only print segments
        if segments {
            file.commands
                .compactMap { (loadCommand: LoadCommand) -> SegmentCommand? in
                    guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
                    return segmentCommand
                }
                .forEach { segmentCommand in
                    CLIFormatter.print(segmentCommand)
                }
            return
        }
        // print default information
        CLIFormatter.print(file)
    }
}

Reader.main()
