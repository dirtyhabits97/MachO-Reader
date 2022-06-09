import Foundation
import ArgumentParser

struct Reader: ParsableCommand {

    // TODO: figure out what to do with these
    // @Flag(name: [.customShort("f"), .customLong("fat")], help: "Only print the fat header.")
    // var onlyFatHeader: Bool = false

    // @Flag(name: [.customShort("h"), .customLong("header")], help: "Only print the mach-o header.")
    // var onlyHeader: Bool = false

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs information for the segment commands.")
    var segments: Bool = false

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    func run() throws {
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
        }
        let file = try MachOFile(from: url, arch: arch)
        // if only print segments
        if segments {
            file.commands
                .compactMap({ (loadCommand: LoadCommand) -> SegmentCommand? in
                    guard case .segmentCommand(let segmentCommand) = loadCommand.commandType() else { return nil }
                    return segmentCommand
                })
                .forEach({ segmentCommand in
                    CLIFormatter.print(segmentCommand)
                })
            return
        }
        CLIFormatter.print(file)
    }
}

Reader.main()
