import Foundation

struct DyldChainedImportBuilder {

    let imports: [DyldChainedImport]

    init(_ fixupsReport: DyldChainedFixupsReport) {
        let dylibCommands = fixupsReport.file.commands.getDylibCommands()
        var imports: [DyldChainedImport] = []

        var offset = Int(fixupsReport.header.importsOffset)
        for _ in 0 ..< fixupsReport.header.importsCount {
            let rawValue = fixupsReport.fixupData
                .advanced(by: offset)
                .extract(dyld_chained_import.self)
            var chainedImport = DyldChainedImport(rawValue)

            chainedImport.dylibName = dylibCommands[Int(chainedImport.libOrdinal) - 1]
                .dylib
                .name
                .split(separator: "/")
                .last?
                .toString()

            let offsetToSymbolName = fixupsReport.header.symbolsOffset + chainedImport.nameOffset
            chainedImport.symbolName = fixupsReport.fixupData
                .advanced(by: Int(offsetToSymbolName))
                .extractString()

            imports.append(chainedImport)
            offset += MemoryLayout.size(ofValue: rawValue)
        }

        self.imports = imports
    }
}

public struct DyldChainedImport {

    public let libOrdinal: UInt8
    public let isWeakImport: Bool
    public let nameOffset: UInt32

    public internal(set) var dylibName: String?
    public internal(set) var symbolName: String?

    init(_ chainedImport: dyld_chained_import) {
        let values = chainedImport.split(using: [8, 1, 23])
        libOrdinal = UInt8(truncatingIfNeeded: values[0])
        isWeakImport = values[1] == 1
        nameOffset = values[2]
    }
}
