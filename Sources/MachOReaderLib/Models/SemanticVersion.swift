import Foundation

public struct SemanticVersion {

    public let major: Int
    public let minor: Int
    public let patch: Int

    init(_ value: UInt32) {
        // Packed as xxxx.yy.zz: 16 bits major, 8 bits minor, 8 bits patch.
        patch = Int(value & 0xFF)
        minor = Int((value >> 8) & 0xFF)
        major = Int(value >> 16)
    }
}

// MARK: - CustomStringConvertible

extension SemanticVersion: CustomStringConvertible {

    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}
