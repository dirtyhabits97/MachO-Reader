import Foundation
import MachO

/// A single entry of the Mach-O symbol table (an `nlist_64`), with its name
/// resolved from the string table.
///
/// Only the 64-bit `nlist_64` layout is supported — the library is
/// 64-bit-focused and there is no 32-bit `nlist` path.
public struct Symbol {

    // MARK: - Properties

    /// Byte index into the string table (`n_strx`). `0` means "no name".
    public let stringTableIndex: UInt32
    /// The symbol type, decoded from `n_type & N_TYPE`.
    public let type: SymbolType
    /// The section number (`n_sect`); `NO_SECT` (0) when not in a section.
    public let sectionNumber: UInt8
    /// The `n_desc` field (named `desc`, not `description`, to avoid colliding
    /// with `CustomStringConvertible`).
    public let desc: UInt16
    /// The symbol's value (`n_value`) — typically an address for defined symbols.
    public let value: UInt64

    /// The symbol name, resolved from the string table during the build.
    public internal(set) var name: String?

    /// The raw `n_type` byte, kept for the mask-bit flags below.
    private let rawType: UInt8

    // MARK: - Lifecycle

    init(_ nlist: nlist_64) {
        stringTableIndex = nlist.n_un.n_strx
        rawType = nlist.n_type
        type = SymbolType(nlist.n_type & UInt8(N_TYPE))
        sectionNumber = nlist.n_sect
        desc = nlist.n_desc
        value = nlist.n_value
    }

    // MARK: - Flags (n_type mask bits)

    /// Whether the symbol is a debugging (STAB) symbol (`N_STAB`).
    public var isStab: Bool {
        rawType & UInt8(N_STAB) != 0
    }

    /// Whether the symbol is a private external symbol (`N_PEXT`).
    public var isPrivateExternal: Bool {
        rawType & UInt8(N_PEXT) != 0
    }

    /// Whether the symbol is external (`N_EXT`).
    public var isExternal: Bool {
        rawType & UInt8(N_EXT) != 0
    }

    // MARK: - Readable

    /// A human-readable description of the set flags and the symbol type,
    /// e.g. `"N_EXT | N_SECT"`.
    public var readableType: String {
        var parts: [String] = []
        if isStab { parts.append("N_STAB") }
        if isPrivateExternal { parts.append("N_PEXT") }
        if isExternal { parts.append("N_EXT") }
        parts.append(type.readableValue ?? String(type.rawValue))
        return parts.joined(separator: " | ")
    }
}

// MARK: - SymbolType

public extension Symbol {

    /// The masked symbol type (`n_type & N_TYPE`).
    struct SymbolType: RawRepresentable, Equatable, Readable, Sendable {

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        init(_ rawValue: UInt8) {
            self.rawValue = rawValue
        }

        // Source: <mach-o/nlist.h>
        public static let undefined = SymbolType(UInt8(N_UNDF))
        public static let absolute = SymbolType(UInt8(N_ABS))
        public static let section = SymbolType(UInt8(N_SECT))
        public static let prebound = SymbolType(UInt8(N_PBUD))
        public static let indirect = SymbolType(UInt8(N_INDR))

        public var readableValue: String? {
            switch self {
            case .undefined: "N_UNDF"
            case .absolute: "N_ABS"
            case .section: "N_SECT"
            case .prebound: "N_PBUD"
            case .indirect: "N_INDR"
            default: nil
            }
        }
    }
}
