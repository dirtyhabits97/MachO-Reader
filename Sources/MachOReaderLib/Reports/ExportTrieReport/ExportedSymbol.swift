import Foundation
import MachO

/// A single entry decoded from the Mach-O export trie (`LC_DYLD_EXPORTS_TRIE`,
/// or the `export_off`/`export_size` blob of `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY`
/// on older binaries) — an `nm -gU` / `dyld_info -exports`-style view of what a
/// binary exports.
public struct ExportedSymbol {

    // MARK: - Properties

    /// The exported symbol name, built from the trie's edge labels on the path to its node.
    public let name: String
    /// The raw `flags` ULEB128 read from the terminal node.
    public let flags: UInt64
    /// The masked `EXPORT_SYMBOL_FLAGS_KIND_MASK` bits.
    public let kind: Kind
    /// Whether `EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION` (0x04) is set.
    public let isWeakDefinition: Bool
    /// Whether `EXPORT_SYMBOL_FLAGS_REEXPORT` (0x08) is set.
    public let isReexport: Bool
    /// Whether `EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER` (0x10) is set.
    public let isStubAndResolver: Bool

    /// The image offset of the symbol. Only set for regular exports (not a
    /// re-export or a stub-and-resolver).
    public let address: UInt64?

    /// The 1-based index into the `LC_LOAD_*DYLIB` order of the dylib this
    /// symbol is re-exported from. Only set when `isReexport` is `true`.
    public let reexportOrdinal: UInt64?
    /// The name to look up in the re-exported dylib. `nil` means the trie
    /// stored an empty string, i.e. the same name as `name`.
    public let reexportName: String?

    /// The stub's image offset. Only set when `isStubAndResolver` is `true`.
    public let stubOffset: UInt64?
    /// The resolver function's image offset. Only set when `isStubAndResolver` is `true`.
    public let resolverOffset: UInt64?

    // MARK: - Lifecycle

    init(
        name: String,
        flags: UInt64,
        address: UInt64? = nil,
        reexportOrdinal: UInt64? = nil,
        reexportName: String? = nil,
        stubOffset: UInt64? = nil,
        resolverOffset: UInt64? = nil,
    ) {
        self.name = name
        self.flags = flags
        kind = Kind(rawValue: flags & UInt64(EXPORT_SYMBOL_FLAGS_KIND_MASK))
        isWeakDefinition = flags & UInt64(EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION) != 0
        isReexport = flags & UInt64(EXPORT_SYMBOL_FLAGS_REEXPORT) != 0
        isStubAndResolver = flags & UInt64(EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER) != 0
        self.address = address
        self.reexportOrdinal = reexportOrdinal
        self.reexportName = reexportName
        self.stubOffset = stubOffset
        self.resolverOffset = resolverOffset
    }
}

// MARK: - Kind

public extension ExportedSymbol {

    /// The masked `EXPORT_SYMBOL_FLAGS_KIND_MASK` (0x03) bits.
    struct Kind: RawRepresentable, Equatable, Readable, Sendable {

        public let rawValue: UInt64

        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        // Source: <mach-o/loader.h>
        public static let regular = Kind(rawValue: UInt64(EXPORT_SYMBOL_FLAGS_KIND_REGULAR))
        public static let threadLocal = Kind(rawValue: UInt64(EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL))
        public static let absolute = Kind(rawValue: UInt64(EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE))

        public var readableValue: String? {
            switch self {
            case .regular: "REGULAR"
            case .threadLocal: "THREAD_LOCAL"
            case .absolute: "ABSOLUTE"
            default: nil
            }
        }
    }
}
