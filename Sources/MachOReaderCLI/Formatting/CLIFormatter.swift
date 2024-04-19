import Foundation
import MachOReaderLib

enum CLIFormatter {

    static func print(_ output: CLIOutput) {
        Swift.print(output.detailed.joined())
    }

    static func printSummary(_ output: CLIOutput) {
        Swift.print(output.summary)
    }
}

protocol CLIOutput {

    var summary: String { get }
    var detailed: [String] { get }
}

extension CLIOutput {

    var detailed: [String] { [summary] }
}
