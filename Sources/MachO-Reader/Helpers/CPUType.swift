import Foundation

struct CPUType: RawRepresentable, Equatable {

    // MARK: - Properties

    let rawValue: cpu_type_t

    // MARK: - Lifecycle

    init(_ rawValue: cpu_type_t) {
        self.rawValue = rawValue
    }

    init(rawValue: cpu_type_t) {
        self.rawValue = rawValue
    }

    // MARK: - Constants

    static let x86 = CPUType(rawValue: CPU_TYPE_X86)
    // swiftlint:disable:next identifier_name
    static let x86_64 = CPUType(rawValue: CPU_TYPE_X86_64)
    static let arm = CPUType(rawValue: CPU_TYPE_ARM)
    // swiftlint:disable:next identifier_name
    static let arm_64 = CPUType(rawValue: CPU_TYPE_ARM64)
}

extension CPUType {

    var readableValue: String {
        switch self {
        case .x86: return "x86"
        case .x86_64: return "x86_64"
        case .arm: return "ARM"
        case .arm_64: return "ARM64"
        default: return String(rawValue)
        }
    }

    init?(from readableValue: String?) {
        guard let readableValue = readableValue else { return nil }
        switch readableValue.lowercased() {
        case "x86": self = .x86
        case "x86_64": self = .x86_64
        case "arm": self = .arm
        case "arm64": self = .arm_64
        default: return nil
        }
    }
}
