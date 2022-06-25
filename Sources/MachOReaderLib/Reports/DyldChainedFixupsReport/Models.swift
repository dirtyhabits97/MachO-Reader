import Foundation

public struct DyldChainedFixupsHeader {
    public let fixupsVersion: UInt32
    public let startsOffset: UInt32
    public let importsOffset: UInt32
    public let symbolsOffset: UInt32
    public let importsCount: UInt32
    // TODO: Create a cmodel for this and transform these 2 properties into raw representable constants.
    public let importsFormat: ImportsFormat
    public let symbolsFormat: SymbolsFormat

    init(_ header: dyld_chained_fixups_header) {
        fixupsVersion = header.fixups_version
        startsOffset = header.starts_offset
        importsOffset = header.imports_offset
        symbolsOffset = header.symbols_offset
        importsCount = header.imports_count

        importsFormat = ImportsFormat(header.imports_format)
        symbolsFormat = SymbolsFormat(header.symbols_format)
    }
}

public extension DyldChainedFixupsHeader {

    struct ImportsFormat: RawRepresentable, Equatable, Readable {

        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        init(_ rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // Source: fixup-chains.h
        static let `import` = ImportsFormat(1)
        static let addend = ImportsFormat(2)
        static let addend64 = ImportsFormat(3)

        public var readableValue: String? {
            switch self {
            case .import: return "DYLD_CHAINED_IMPORT"
            case .addend: return "DYLD_CHAINED_IMPORT_ADDEND"
            case .addend64: return "DYLD_CHAINED_IMPORT_ADDEND_64"
            default: return nil
            }
        }
    }

    struct SymbolsFormat: RawRepresentable, Equatable, Readable {

        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        init(_ rawValue: UInt32) {
            self.rawValue = rawValue
        }

        // Source: fixup-chains.h
        static let uncompressed = SymbolsFormat(0)
        static let zlibCompressed = SymbolsFormat(1)

        public var readableValue: String? {
            switch self {
            case .uncompressed: return "UNCOMPRESSED"
            case .zlibCompressed: return "ZLIB COMPRESSED"
            default: return nil
            }
        }
    }
}

// This struct is embedded in LC_DYLD_CHAINED_FIXUPS payload
// struct dyld_chained_starts_in_image
// {
//     uint32_t    seg_count;
//     uint32_t    seg_info_offset[1];  // each entry is offset into this struct for that segment
//     // followed by pool of dyld_chain_starts_in_segment data
// };
// TODO: move this back to cmodels, we don't need to present this data in the report
public struct DyldChainedStartsInImage: CustomExtractable {

    public let segCount: UInt32
    public let segInfoOffset: [UInt32]

    init(from data: Data) {
        segCount = data.extract(UInt32.self)
        segInfoOffset = data
            .advanced(by: MemoryLayout.size(ofValue: segCount))
            .extractArray(UInt32.self, count: Int(segCount))
    }
}
