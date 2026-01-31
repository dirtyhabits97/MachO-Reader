import Foundation

public struct CPUType: RawRepresentable, Equatable, Sendable {

    // MARK: - Properties

    public let rawValue: cpu_type_t

    // MARK: - Lifecycle

    public init(_ rawValue: cpu_type_t) {
        self.rawValue = rawValue
    }

    public init(rawValue: cpu_type_t) {
        self.rawValue = rawValue
    }

    // MARK: - Constants

    static let x86 = CPUType(rawValue: CPU_TYPE_X86)
    // swiftlint:disable:next identifier_name
    static let x86_64 = CPUType(rawValue: CPU_TYPE_X86_64)
    static let arm = CPUType(rawValue: CPU_TYPE_ARM)
    static let arm64 = CPUType(rawValue: CPU_TYPE_ARM64)
}

// MARK: - Readable

extension CPUType: Readable {

    public var readableValue: String? {
        switch self {
        case .x86: return "x86"
        case .x86_64: return "x86_64"
        case .arm: return "ARM"
        case .arm64: return "ARM64"
        default: return nil
        }
    }

    init?(from readableValue: String?) {
        guard let readableValue = readableValue else { return nil }
        switch readableValue.lowercased() {
        case "x86": self = .x86
        case "x86_64": self = .x86_64
        case "arm": self = .arm
        case "arm64": self = .arm64
        default: return nil
        }
    }
}
