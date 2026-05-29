import ArgumentParser
import Foundation
import MachOReaderLib

struct DyldChainedFixupsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "chained-fixups")

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs the chained header.")
    var chainedHeader: Bool = false

    @Flag(help: "Only outputs the imports.")
    var imports: Bool = false

    @Flag(help: "Only outputs the pages.")
    var pages: Bool = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        let expandedPath = (pathToBinary as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        let file = try MachOFile(from: url, arch: arch)
        let report = file.dyldChainedFixupsReport()

        switch format {
        case .text:
            printText(report: report)
        case .json:
            printJSON(report: report)
        }
    }

    // MARK: - Text Output

    private func printText(report: DyldChainedFixupsReport) {
        let formatter = TextFormatter()

        if chainedHeader {
            print(formatter.format(report.header))
            return
        }

        if imports {
            for imp in report.imports {
                print(formatter.format(imp))
            }
            return
        }

        if pages {
            for (segmentInfo, pages) in zip(report.segmentInfo, report.pageInfo()) {
                print(formatter.format(segmentInfo))
                print(formatter.format(pages))
            }
            return
        }

        print(formatter.format(report))
    }

    // MARK: - JSON Output

    private func printJSON(report: DyldChainedFixupsReport) {
        let formatter = JSONFormatter()

        if chainedHeader {
            print(formatter.toJSONString(formatter.format(report.header)))
            return
        }

        if imports {
            let importsArray = report.imports.map { formatter.format($0) }
            print(formatter.toJSONString(importsArray))
            return
        }

        if pages {
            var result: [[String: Any]] = []
            for (segmentInfo, pages) in zip(report.segmentInfo, report.pageInfo()) {
                var segmentDict = formatter.format(segmentInfo)
                segmentDict["pages"] = formatter.format(pages)
                result.append(segmentDict)
            }
            print(formatter.toJSONString(result))
            return
        }

        print(formatter.toJSONString(formatter.format(report)))
    }
}
