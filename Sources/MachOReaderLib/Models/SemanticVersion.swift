import Foundation

public struct SemanticVersion {

    let major: Int
    let minor: Int
    let patch: Int

    init(_ value: UInt32) {
        let mask: UInt32 = 0b1111
        // get the last 8 bytes
        patch = Int(value & mask)
        // get bytes 9-16
        minor = Int((value >> 8) & mask)
        // get bytes 17-32
        major = Int((value >> 16))
    }
}

// MARK: - CustomStringConvertible

extension SemanticVersion: CustomStringConvertible {

    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}
