import Foundation
import ArgumentParser

struct Reader: ParsableCommand {

    @Flag(name: [.customShort("f"), .customLong("fat")], help: "Only print the fat header.")
    var onlyFatHeader: Bool = false

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    func run() throws {
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
        }
        let file = try MachOFile(from: url)
        if onlyFatHeader {
            if let fatHeader = file.fatHeader {
                CLIFormatter.print(fatHeader)
            }
            return
        }
        // CLIFormatter.output(file: try MachOFile(from: url))
    }
}

Reader.main()
