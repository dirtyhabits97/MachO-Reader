import ArgumentParser
import Foundation
import MachOReaderLib

struct SymbolsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "symbols",
                                                    abstract: "List the symbol table (LC_SYMTAB) entries.")

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs undefined symbols (N_UNDF).")
    var undefined: Bool = false

    @Flag(help: "Only outputs external symbols (N_EXT).")
    var external: Bool = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    // MARK: - Methods

    func run() throws {
        let expandedPath = (pathToBinary as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        let file = try MachOFile(from: url, arch: arch)
        let report = try file.symbolTableReport()

        let symbols = filtered(report.symbols)

        switch format {
        case .text:
            printText(symbols: symbols)
        case .json:
            printJSON(symbols: symbols)
        }
    }

    private func filtered(_ symbols: [Symbol]) -> [Symbol] {
        symbols.filter { symbol in
            (!undefined || symbol.type == .undefined) && (!external || symbol.isExternal)
        }
    }

    // MARK: - Text Output

    private func printText(symbols: [Symbol]) {
        let formatter = TextFormatter()

        print("SYMBOLS (\(symbols.count)):")
        for (idx, symbol) in symbols.enumerated() {
            print("[\(idx)]".padding(6) + formatter.format(symbol))
        }
    }

    // MARK: - JSON Output

    private func printJSON(symbols: [Symbol]) {
        let formatter = JSONFormatter()

        let symbolsArray = symbols.enumerated().map { idx, symbol -> [String: Any] in
            var result = formatter.format(symbol)
            result["index"] = idx
            return result
        }
        print(formatter.toJSONString(symbolsArray))
    }
}
