import ArgumentParser
import Foundation
import MachOReaderLib

struct ExportsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "exports",
                                                    abstract: "List the exported symbols (export trie) entries.")

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs weak-defined symbols.")
    var weak: Bool = false

    @Flag(help: "Only outputs re-exported symbols.")
    var reexports: Bool = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        let expandedPath = (pathToBinary as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        let file = try MachOFile(from: url, arch: arch)
        let report = try file.exportTrieReport()

        let symbols = filtered(report.symbols)

        switch format {
        case .text:
            printText(symbols: symbols)
        case .json:
            printJSON(symbols: symbols)
        }
    }

    private func filtered(_ symbols: [ExportedSymbol]) -> [ExportedSymbol] {
        symbols.filter { symbol in
            (!weak || symbol.isWeakDefinition) && (!reexports || symbol.isReexport)
        }
    }

    // MARK: - Text Output

    private func printText(symbols: [ExportedSymbol]) {
        let formatter = TextFormatter()

        print("EXPORTS (\(symbols.count)):")
        for (idx, symbol) in symbols.enumerated() {
            print("[\(idx)]".padding(6) + formatter.format(symbol))
        }
    }

    // MARK: - JSON Output

    private func printJSON(symbols: [ExportedSymbol]) {
        let formatter = JSONFormatter()

        let symbolsArray = symbols.enumerated().map { idx, symbol -> [String: Any] in
            var result = formatter.format(symbol)
            result["index"] = idx
            return result
        }
        print(formatter.toJSONString(symbolsArray))
    }
}
