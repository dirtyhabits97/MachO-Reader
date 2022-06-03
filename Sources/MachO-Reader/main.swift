import Foundation
import ArgumentParser

struct Reader: ParsableCommand {

    // TODO: figure out what to do with these
    // @Flag(name: [.customShort("f"), .customLong("fat")], help: "Only print the fat header.")
    // var onlyFatHeader: Bool = false

    // @Flag(name: [.customShort("h"), .customLong("header")], help: "Only print the mach-o header.")
    // var onlyHeader: Bool = false

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    func run() throws {
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
        }
        let file = try MachOFile(from: url)

        if let fatHeader = file.fatHeader {
            CLIFormatter.print(fatHeader)
        }
        print("") // padding
        CLIFormatter.print(file.header)
        // CLIFormatter.output(file: try MachOFile(from: url))
    }
}

Reader.main()
