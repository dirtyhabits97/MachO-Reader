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
