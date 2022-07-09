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
        var str = "PAGE \(idx) (offset: \(offset))"

        for element in bindOrRebase {
            str += "\n   "
            str += element.cli
        }

        return str
    }
}

extension DyldChainedSegmentInfo.Pages: CLIOutput {

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

extension DyldChainedPtr64Bind: CLIOutput {

    var cli: String {
        var str = "BIND"
        str += "   "
        str += "ordinal: \(ordinal)"
        str += "   "
        str += "addend: \(addend)"
        return str
    }
}

extension DyldChainedPtr32Bind: CLIOutput {

    var cli: String {
        var str = "BIND"
        str += "   "
        str += "ordinal: \(ordinal)"
        str += "   "
        str += "addend: \(addend)"
        return str
    }
}

extension DyldChainedPtr64Rebase: CLIOutput {

    var cli: String {
        var str = "REBASE"
        str += "   "
        str += "target: \(target)"
        str += "   "
        str += "high8: \(high8)"
        return str
    }
}

extension DyldChainedPtr32Rebase: CLIOutput {

    var cli: String {
        var str = "REBASE"
        str += "   "
        str += "target: \(target)"
        return str
    }
}

extension DyldChainedPtr64KernelCacheRebase: CLIOutput {

    var cli: String {
        var str = "CACHE REBASE"
        str += "   "
        str += "target: \(target)"
        str += "   "
        str += "cacheLevel: \(cacheLevel)"
        str += "   "
        str += "diversity: \(diversity)"
        str += "   "
        str += "addrDiv: \(addrDiv)"
        str += "   "
        str += "key: \(key)"
        str += "   "
        str += "isAuth: \(isAuth)"
        return str
    }
}

extension DyldChainedPtr32CacheRebase: CLIOutput {

    var cli: String {
        var str = "CACHE REBASE"
        str += "   "
        str += "target: \(target)"
        return str
    }
}

extension DyldChainedPtr32FirmwareRebase: CLIOutput {

    var cli: String {
        var str = "FIRMWARE REBASE"
        str += "   "
        str += "target: \(target)"
        return str
    }
}

extension DyldChainedPtrBindOrRebase: CLIOutput {

    var cli: String {
        switch underlyingValue {
        case let .bind32(bind):
            return bind.cli
        case let .bind64(bind):
            return bind.cli
        case let .rebase32(rebase):
            return rebase.cli
        case let .rebase64(rebase):
            return rebase.cli
        case let .kernelCacheRebase(rebase):
            return rebase.cli
        case let .cacheRebase(rebase):
            return rebase.cli
        case let .firmwareRebase(rebase):
            return rebase.cli
        }
    }
}
