import Foundation

// MARK: - Hex Formatters

extension String {

    init(hex: UInt32) {
        self.init("0x" + String(format: "%08llx", hex))
    }

    init(hex: Int32) {
        self.init("0x" + String(format: "%08llx", hex))
    }

    init(hex: UInt64) {
        self.init("0x" + String(format: "%09llx", hex))
    }
}

// MARK: - CLI-specific Formatters

extension String {

    static func cmd(_ cmd: UInt32) -> String {
        "0x" + String(format: "%08llx", cmd)
    }

    static func filetype(_ filetype: Int) -> String {
        "0x" + String(format: "%08llx", filetype)
    }

    static func flags(_ flags: UInt32) -> String {
        "0x" + String(format: "%08llx", flags)
    }

    static func magic(_ magic: UInt32) -> String {
        "0x" + String(format: "%08llx", magic)
    }
}

// MARK: - Utils

extension String {

    func padding(_ length: Int) -> String {
        // if the current string is equal or greater than the length,
        // add 3 trailing whitespaces as padding
        if count >= length { return self + "   " }
        return padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
