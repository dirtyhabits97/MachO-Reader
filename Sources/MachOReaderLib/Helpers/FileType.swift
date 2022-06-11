import Foundation

public struct FileType: RawRepresentable, Equatable {

    // MARK: - Properties

    public let rawValue: Int

    // MARK: - Lifecycle

    public init(_ rawValue: Int32) {
        self.rawValue = Int(rawValue)
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = Int(rawValue)
    }

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: - Constants

    static let object = FileType(MH_OBJECT)
    static let execute = FileType(MH_EXECUTE)
    static let dylib = FileType(MH_DYLIB)
    static let dylinker = FileType(MH_DYLINKER)
    static let bundle = FileType(MH_BUNDLE)
    static let dsym = FileType(MH_DSYM)
}

// MARK: - Readable

extension FileType: Readable {

    public var readableValue: String? {
        switch self {
        case .object: return "MH_OBJECT"
        case .execute: return "MH_EXECUTE"
        case .dylib: return "MH_DYLIB"
        case .dylinker: return "MH_DYLINKER"
        case .bundle: return "MH_BUNDLE"
        case .dsym: return "MH_DSYM"
        default: return nil
        }
    }
}
