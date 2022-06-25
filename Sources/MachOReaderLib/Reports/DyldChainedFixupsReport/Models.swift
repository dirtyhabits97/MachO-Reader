import Foundation

// TODO: rename this file to DyldChainedFixupsHeader.
public struct DyldChainedFixupsHeader {

    public let fixupsVersion: UInt32
    public let startsOffset: UInt32
    public let importsOffset: UInt32
    public let symbolsOffset: UInt32
    public let importsCount: UInt32

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
