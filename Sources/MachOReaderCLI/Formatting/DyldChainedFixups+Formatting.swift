import Foundation
import MachOReaderLib

extension DyldChainedFixupsHeader: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        [
            "CHAINED_FIXUPS_HEADER".padding(25),
            "starts_offset: \(startsOffset)",
            "   ",
            "imports_offset: \(importsOffset)",
            "   ",
            "imports_count: \(importsCount)",
            "   ",
            "symbols_offset: \(symbolsOffset)",
            "\n".padding(26),
            "imports_format: \(importsFormat.readableValue ?? String(importsFormat.rawValue))",
            "   ",
            "symbols_format: \(symbolsFormat.readableValue ?? String(symbolsFormat.rawValue))",
        ]
    }
}

extension DyldChainedImport: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        var output = [
            "lib_ordinal: ",
            "\(libOrdinal)".padding(6),
            "weak_import: ",
            "\(isWeakImport)".padding(8),
            "name_offset: ",
            "\(nameOffset)".padding(8),
        ]
        if let dylib = dylibName, let symbol = symbolName {
            output.append("(\(dylib), \(symbol))")
        }
        return output
    }
}

extension DyldChainedSegmentInfo: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        var output = ["SEGMENT \(segmentName) (offset: \(segInfoOffset))"]

        if let startsInSegment = startsInSegment {
            output.append(contentsOf: [
                "\n",
                startsInSegment.summary,
            ])
            output.append(contentsOf: ["\n"] + startsInSegment.detailed)
        }
        return output
    }
}

extension DyldChainedSegmentInfo.StartsInSegment {

    var summary: String { detailed.joined(separator: "\n") }

    var detailed: [String] {
        [
            "   size: \(size)",
            "   page_size: \(pageSize)",
            "   pointer_format: \(pointerFormat.readableValue ?? String(pointerFormat.rawValue))",
            "   segment_offset: \(segmentOffset)",
            "   max_valid_pointer: \(maxValidPointer)",
            "   page_count: \(pageCount)",
            "   page_start: \(pageStart[0])",
        ]
    }
}

extension DyldChainedSegmentInfo.PageInfo: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        var output = ["PAGE \(idx) (offset: \(offset))"]

        for element in bindOrRebase {
            output.append(contentsOf: ["\n"] + element.detailed)
        }

        return output
    }
}

extension DyldChainedSegmentInfo.Pages: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        var output = [String]()
        for page in pages {
            output.append(contentsOf: ["\n"] + page.detailed)
        }
        return output
    }
}

extension DyldChainedFixupsReport: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        var output = header.detailed + ["\n"]
        for seg in segmentInfo {
            output.append(contentsOf: ["\n"] + seg.detailed)
        }
        output.append("\n\nIMPORTS:")
        for (idx, imp) in imports.enumerated() {
            output.append("\n   ")
            output.append("[\(idx)]".padding(6))
            output.append(contentsOf: imp.detailed)
        }
        return output
    }
}

extension DyldChainedPtr64Bind: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        [
            "BIND",
            "   ",
            "ordinal: \(ordinal)",
            "   ",
            "addend: \(addend)",
        ]
    }
}

extension DyldChainedPtr32Bind: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        [
            "BIND",
            "   ",
            "ordinal: \(ordinal)",
            "   ",
            "addend: \(addend)",
        ]
    }
}

extension DyldChainedPtr64Rebase: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        [
            "REBASE",
            "   ",
            "target: \(target)",
            "   ",
            "high8: \(high8)",
        ]
    }
}

extension DyldChainedPtr32Rebase: CLIOutput {

    var summary: String { detailed.joined() }

    var detailed: [String] {
        [
            "REBASE",
            "   ",
            "target: \(target)",
        ]
    }
}

extension DyldChainedPtrBindOrRebase: CLIOutput {

    var summary: String {
        switch underlyingValue {
        case let .bind32(bind):
            return bind.summary
        case let .bind64(bind):
            return bind.summary
        case let .rebase32(rebase):
            return rebase.summary
        case let .rebase64(rebase):
            return rebase.summary
        }
    }

    var detailed: [String] {
        switch underlyingValue {
        case let .bind32(bind):
            return bind.detailed
        case let .bind64(bind):
            return bind.detailed
        case let .rebase32(rebase):
            return rebase.detailed
        case let .rebase64(rebase):
            return rebase.detailed
        }
    }
}
