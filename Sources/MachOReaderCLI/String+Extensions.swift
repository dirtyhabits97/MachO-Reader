import Foundation

extension String {

    init(hex: UInt64) {
        self.init("0x" + String(format: "%09llx", hex))
    }

    static func cmd(_ cmd: UInt32) -> String {
        self.init("0x" + String(format: "%08llx", cmd))
    }

    static func filetype(_ filetype: Int) -> String {
        self.init("0x" + String(format: "%08llx", filetype))
    }

    static func flags(_ flags: UInt32) -> String {
        self.init("0x" + String(format: "%08llx", flags))
    }

    static func magic(_ magic: UInt32) -> String {
        self.init("0x" + String(format: "%08llx", magic))
    }
}
