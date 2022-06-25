import Foundation
import MachOReaderLib

extension DyldChainedImport: CLIOutput {

    var cli: String {
        var str = "lib_ordinal: "
        str += "\(libOrdinal)".padding(6)
        str += "weak_import: "
        str += "\(isWeakImport)".padding(8)
        str += "name_offset: "
        str += "\(nameOffset)".padding(8)
        if let dylib = dylibName, let symbol = symbolName {
            str += "(\(dylib), \(symbol))"
        }
        return str
    }
}

extension DyldChainedSegmentInfo: CLIOutput {

    var cli: String {
        let str = "SEGMENT \(segmentName) (offset: \(segInfoOffset))"
        // TODO: finish implementing this
        return str
    }
}

extension DyldChainedSegmentInfo.PageInfo: CLIOutput {

    var cli: String {
        let str = "PAGE \(idx) (offset: \(offset))"
        // TODO: finish implementing this
        return str
    }
}

extension DyldChainedSegmentInfo.Pages: CLIOutput {

    // TODO: implement this correctly
    var cli: String {
        var str = ""
        for page in pages {
            str += "\n\(page.cli)"
        }
        return str
    }
}
