import Foundation

extension String {

    static func magic(_ magic: UInt32) -> String {
        self.init("0x" + String(format: "%08llx", magic))
    }
}
