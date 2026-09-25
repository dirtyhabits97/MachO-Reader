import Foundation
import MachO

/// A single rebase fixup decoded from a classic `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY`
/// rebase opcode stream (`REBASE_OPCODE_*` in `mach-o/loader.h`).
public struct RebaseEntry {

    public let segmentIndex: Int
    public let segmentName: String
    public let sectionName: String?
    public let address: UInt64
    public let type: RebaseType
}

public extension RebaseEntry {

    /// The rebase kind (`REBASE_OPCODE_SET_TYPE_IMM`'s immediate).
    struct RebaseType: RawRepresentable, Equatable, Readable, Sendable {

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        init(_ rawValue: UInt8) {
            self.rawValue = rawValue
        }

        // Source: <mach-o/loader.h>
        public static let pointer = RebaseType(UInt8(REBASE_TYPE_POINTER))
        public static let textAbsolute32 = RebaseType(UInt8(REBASE_TYPE_TEXT_ABSOLUTE32))
        public static let textPCRelative32 = RebaseType(UInt8(REBASE_TYPE_TEXT_PCREL32))

        public var readableValue: String? {
            switch self {
            case .pointer: "REBASE_TYPE_POINTER"
            case .textAbsolute32: "REBASE_TYPE_TEXT_ABSOLUTE32"
            case .textPCRelative32: "REBASE_TYPE_TEXT_PCREL32"
            default: nil
            }
        }
    }
}

/// A single bind fixup decoded from a classic `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY`
/// bind, weak-bind or lazy-bind opcode stream (`BIND_OPCODE_*` in `mach-o/loader.h`).
public struct BindEntry {

    public let kind: Kind
    public let segmentIndex: Int
    public let segmentName: String
    public let sectionName: String?
    public let address: UInt64
    public let type: BindType
    public let dylibOrdinal: Int
    public let dylibName: String?
    public let symbolName: String
    public let addend: Int64
    public let isWeakImport: Bool
}

public extension BindEntry {

    /// Which of the three opcode streams this entry came from.
    enum Kind: Sendable {
        case bind
        case weak
        case lazy
    }

    /// The bind kind (`BIND_OPCODE_SET_TYPE_IMM`'s immediate).
    struct BindType: RawRepresentable, Equatable, Readable, Sendable {

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        init(_ rawValue: UInt8) {
            self.rawValue = rawValue
        }

        // Source: <mach-o/loader.h>
        public static let pointer = BindType(UInt8(BIND_TYPE_POINTER))
        public static let textAbsolute32 = BindType(UInt8(BIND_TYPE_TEXT_ABSOLUTE32))
        public static let textPCRelative32 = BindType(UInt8(BIND_TYPE_TEXT_PCREL32))

        public var readableValue: String? {
            switch self {
            case .pointer: "BIND_TYPE_POINTER"
            case .textAbsolute32: "BIND_TYPE_TEXT_ABSOLUTE32"
            case .textPCRelative32: "BIND_TYPE_TEXT_PCREL32"
            default: nil
            }
        }
    }
}
