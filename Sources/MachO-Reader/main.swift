import Foundation
import ArgumentParser

struct Reader: ParsableCommand {

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    func run() throws {
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
        }
        CLIFormatter.output(file: try MachOFile(from: url))
    }
}

Reader.main()
