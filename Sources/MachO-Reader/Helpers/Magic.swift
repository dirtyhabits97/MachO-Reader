import Foundation
import MachO

struct Magic: RawRepresentable, Equatable {

    // MARK: - Properties

    let rawValue: UInt32

    var isFat: Bool {
        [.fatMagic, .fatMagic64, .fatCigam, .fatCigam64].contains(self)
    }

    var isMagic64: Bool {
        [.magic64, .cigam64, .fatMagic64, .fatCigam64].contains(self)
    }

    var isSwapped: Bool {
        [.cigam, .cigam64, .fatCigam, .fatCigam64].contains(self)
    }

    // MARK: - Lifecycle

    init(peak data: Data) {
        self.rawValue = data.extract(UInt32.self)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(rawValue: UInt32) {
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

extension Magic: CustomStringConvertible {

    var description: String {
        let pretty: String
        switch self {
        case .fatMagic: pretty = "FAT_MAGIC"
        case .fatCigam: pretty = "FAT_CIGAM"
        case .fatMagic64: pretty = "FAT_MAGIC_64"
        case .fatCigam64: pretty = "FAT_CIGAM_64"
        case .magic: pretty = "MH_MAGIC"
        case .cigam: pretty = "MH_CIGAM"
        case .magic64: pretty = "MH_MAGIC_64"
        case .cigam64: pretty = "MH_CIGAM_64"
        default: return String.magic(rawValue)
        }
        return "\(pretty) (\(String.magic(rawValue)))"
    }
}
