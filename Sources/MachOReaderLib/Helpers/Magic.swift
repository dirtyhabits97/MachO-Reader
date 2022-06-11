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

    init(peek data: Data) {
        rawValue = data.extract(UInt32.self)
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
