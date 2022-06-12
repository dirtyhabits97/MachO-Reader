import Foundation
import MachOReaderLib

enum CLIFormatter {

    static func print(_ output: CLIOutput) {
        Swift.print(output.cli)
    }
}

protocol CLIOutput {

    var cli: String { get }
    var cliCompact: String { get }
}

extension CLIOutput {

    var cliCompact: String { cli }
}
