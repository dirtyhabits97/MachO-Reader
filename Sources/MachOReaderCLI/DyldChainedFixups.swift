import ArgumentParser
import Foundation
import MachOReaderLib

struct DyldChainedFixupsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "chained-fixups")

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs the imports.")
    var imports: Bool = false

    @Flag(help: "Only outputs the pages.")
    var pages: Bool = false

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        guard let url = URL(string: "file://\(pathToBinary)") else {
            print("Could not create url for \(pathToBinary)")
            return
        }
        let file = try MachOFile(from: url, arch: arch)
        let report = file.dyldChainedFixupsReport()

        if imports {
            for imp in report.imports {
                CLIFormatter.print(imp)
            }
            return
        }

        if pages {
            for (segmentInfo, pages) in zip(report.segmentInfo, report.pageInfo()) {
                CLIFormatter.print(segmentInfo)
                CLIFormatter.print(pages)
            }
            return
        }

        CLIFormatter.print(file.dyldChainedFixupsReport())
    }
}
