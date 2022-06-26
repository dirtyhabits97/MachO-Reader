import Foundation
import MachOReaderLib

extension DyldChainedFixupsHeader: CLIOutput {

    var cli: String {
        var str = "CHAINED_FIXUPS_HEADER".padding(25)
        str += "starts_offset: \(startsOffset)"
        str += "   "
        str += "imports_offset: \(importsOffset)"
        str += "   "
        str += "imports_count: \(importsCount)"
        str += "   "
        str += "symbols_offset: \(symbolsOffset)"
        str += "\n".padding(26)
        str += "imports_format: \(importsFormat.readableValue ?? String(importsFormat.rawValue))"
        str += "   "
        str += "symbols_format: \(symbolsFormat.readableValue ?? String(symbolsFormat.rawValue))"
        return str
    }
}

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
        var str = "SEGMENT \(segmentName) (offset: \(segInfoOffset))"
        if let startsInSegment = startsInSegment {
            str += "\n\(startsInSegment.cli)"
        }
        return str
    }
}

extension DyldChainedSegmentInfo.StartsInSegment {

    var cli: String {
        [
            "   size: \(size)",
            "   page_size: \(pageSize)",
            // TODO: this should be a raw representable struct
            "   pointer_format: \(pointerFormat.readableValue ?? String(pointerFormat.rawValue))",
            "   segment_offset: \(segmentOffset)",
            "   max_valid_pointer: \(maxValidPointer)",
            "   page_count: \(pageCount)",
            "   page_start: \(pageStart[0])",
        ]
        .joined(separator: "\n")
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

extension DyldChainedFixupsReport: CLIOutput {

    var cli: String {
        var str = header.cli
        str += "\n"
        for seg in segmentInfo {
            str += "\n\(seg.cli)"
        }
        str += "\n\nIMPORTS:"
        for (idx, imp) in imports.enumerated() {
            str += "\n   "
            str += "[\(idx)]".padding(6)
            str += imp.cli
        }
        return str
    }
}
