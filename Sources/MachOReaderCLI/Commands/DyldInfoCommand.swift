import ArgumentParser
import Foundation
import MachOReaderLib

/// Named `DyldInfoSubcommand` (not `DyldInfoCommand`) to avoid clashing with
/// `MachOReaderLib.DyldInfoCommand`, the `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` load-command model.
struct DyldInfoSubcommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "dyld-info",
        abstract: "Decode the classic LC_DYLD_INFO/LC_DYLD_INFO_ONLY rebase and bind opcode streams.",
    )

    // MARK: - Properties

    @Option(help: "The arch of the mach-o header to read.")
    var arch: String?

    @Flag(help: "Only outputs rebases.")
    var rebase: Bool = false

    @Flag(help: "Only outputs binds.")
    var bind: Bool = false

    @Flag(name: .customLong("weak-bind"), help: "Only outputs weak binds.")
    var weakBind: Bool = false

    @Flag(name: .customLong("lazy-bind"), help: "Only outputs lazy binds.")
    var lazyBind: Bool = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Argument(help: "The binary to inspect.")
    var pathToBinary: String

    private var showsAll: Bool {
        !(rebase || bind || weakBind || lazyBind)
    }

    // MARK: - Methods

    func run() throws {
        let expandedPath = (pathToBinary as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        let file = try MachOFile(from: url, arch: arch)
        let report = try file.dyldInfoReport()

        switch format {
        case .text:
            printText(report: report)
        case .json:
            printJSON(report: report)
        }
    }

    // MARK: - Text Output

    private func printText(report: DyldInfoReport) {
        let formatter = TextFormatter()
        var sections: [String] = []

        if showsAll || rebase {
            sections.append(formatter.formatRebases(report.rebases))
        }
        if showsAll || bind {
            sections.append(formatter.formatBinds(report.binds, title: "BINDS"))
        }
        if showsAll || weakBind {
            sections.append(formatter.formatBinds(report.weakBinds, title: "WEAK BINDS"))
        }
        if showsAll || lazyBind {
            sections.append(formatter.formatBinds(report.lazyBinds, title: "LAZY BINDS"))
        }

        print(sections.joined(separator: "\n\n"))
    }

    // MARK: - JSON Output

    private func printJSON(report: DyldInfoReport) {
        let formatter = JSONFormatter()

        if showsAll {
            print(formatter.toJSONString(formatter.format(report)))
            return
        }

        var result: [String: Any] = [:]
        if rebase {
            result["rebases"] = report.rebases.map { formatter.format($0) }
        }
        if bind {
            result["binds"] = report.binds.map { formatter.format($0) }
        }
        if weakBind {
            result["weakBinds"] = report.weakBinds.map { formatter.format($0) }
        }
        if lazyBind {
            result["lazyBinds"] = report.lazyBinds.map { formatter.format($0) }
        }
        print(formatter.toJSONString(result))
    }
}
