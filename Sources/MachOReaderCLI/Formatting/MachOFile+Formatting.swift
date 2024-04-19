import Foundation
import MachOReaderLib

extension MachOFile: CLIOutput {

    // As a summary, return the header
    var summary: String {
        if let fatHeader {
            return fatHeader.summary
        }
        return header.summary
    }

    var detailed: [String] {
        var output = [String]()

        if let fatHeader {
            output.append(contentsOf: fatHeader.detailed + ["\n\n"])
        }

        output.append(contentsOf: header.detailed + ["\n"])

        for command in commands {
            output.append(contentsOf: ["\n", command.commandType().summary])
        }

        return output
    }
}
