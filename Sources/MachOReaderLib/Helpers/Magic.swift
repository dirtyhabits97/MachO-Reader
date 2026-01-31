import Foundation
import MachO

public struct Magic: RawRepresentable, Equatable {

    // MARK: - Properties

    public let rawValue: UInt32

    var isFat: Bool {
        [.fatMagic, .fatMagic64, .fatCigam, .fatCigam64].contains(self)
    }

    var isMagic64: Bool {
        [.magic64, .cigam64, .fatMagic64, .fatCigam64].contains(self)
    }

    var isSwapped: Bool {
        [.cigam, .cigam64, .fatCigam, .fatCigam64].contains(self)
    }

    var isValid: Bool {
        [.magic, .cigam, .magic64, .cigam64, .fatMagic, .fatCigam, .fatMagic64, .fatCigam64].contains(self)
    }

    // MARK: - Lifecycle

    public init(peek data: Data) {
        guard let value = try? data.decode(UInt32.self, at: 0) else {
            fatalError("Failed to decode magic from data of size \(data.count)")
        }
        rawValue = value
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: - Constants

    // Fat headers
    static let fatMagic = Magic(FAT_MAGIC)
    static let fatCigam = Magic(FAT_CIGAM)
    static let fatMagic64 = Magic(FAT_MAGIC_64)
    static let fatCigam64 = Magic(FAT_CIGAM_64)

    // MachO headers
    static let magic = Magic(MH_MAGIC)
    static let cigam = Magic(MH_CIGAM)
    static let magic64 = Magic(MH_MAGIC_64)
    static let cigam64 = Magic(MH_CIGAM_64)
}

// MARK: - Readable

extension Magic: Readable {

    public var readableValue: String? {
        switch self {
        case .fatMagic: return "FAT_MAGIC"
        case .fatCigam: return "FAT_CIGAM"
        case .fatMagic64: return "FAT_MAGIC_64"
        case .fatCigam64: return "FAT_CIGAM_64"
        case .magic: return "MH_MAGIC"
        case .cigam: return "MH_CIGAM"
        case .magic64: return "MH_MAGIC_64"
        case .cigam64: return "MH_CIGAM_64"
        default: return nil
        }
    }
}
