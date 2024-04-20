import Foundation

// NOTE: The cpu_subtype_t alone is not enough to determine the "label"
// Example: CPU_SUBTYPE_X86_ALL and CPU_SUBTYPE_X86_64_ALL have the same value (3)
// We only know the "label" once we know what's their CPUType
//
// Source: include/mach/machine.h
public struct CPUSubType: RawRepresentable, Equatable {

    // MARK: - Properties

    public let rawValue: cpu_subtype_t

    // MARK: - Lifecycle

    public init(rawValue: cpu_subtype_t) {
        // WARN: Sometimes these values will come masked,
        // we can unmask them before setting the rawValue
        let mask = Int32(bitPattern: CPU_SUBTYPE_PTRAUTH_ABI)
        let unmasked = rawValue & ~mask
        self.rawValue = unmasked
    }

    public init(_ rawValue: cpu_subtype_t) {
        self.init(rawValue: rawValue)
    }

    // MARK: - Constants

    // x86 CPU subtypes
    static let cpuSubTypeX86All = CPUSubType(CPU_SUBTYPE_X86_64_ALL)
    static let cpuSubTypeX86Arch1 = CPUSubType(CPU_SUBTYPE_X86_ARCH1)
    // x86_64 CPU subtypes
    static let cpuSubTypeX8664All = CPUSubType(CPU_SUBTYPE_X86_64_ALL)
    static let cpuSubTypeX8664H = CPUSubType(CPU_SUBTYPE_X86_64_H)
    // arm64 CPU subtypes
    static let cpuSubTypeArm64All = CPUSubType(CPU_SUBTYPE_ARM64_ALL)
    static let cpuSubTypeArm64V8 = CPUSubType(CPU_SUBTYPE_ARM64_V8)
    static let cpuSubTypeArm64E = CPUSubType(CPU_SUBTYPE_ARM64E)

    public func readableValue(cpuType: CPUType) -> String? {
        switch cpuType {
        case .x86: return asX86CpuSubtype
        case .x86_64: return asX86_64CpuSubType
        case .arm: return asArmCpuSubType
        case .arm64: return asArm64CpuSubType
        default: return nil
        }
    }

    // MARK: - Helpers

    var asX86CpuSubtype: String? {
        switch self {
        case .cpuSubTypeX8664All: return "ALL"
        case .cpuSubTypeX86Arch1: return "ARCH1"
        default: return nil
        }
    }

    // swiftlint:disable:next identifier_name
    var asX86_64CpuSubType: String? {
        switch self {
        case .cpuSubTypeX8664All: return "ALL"
        case .cpuSubTypeX8664H: return "H"
        default: return nil
        }
    }

    // TODO: Implement these at some point. Too lazy to do it now.
    var asArmCpuSubType: String? {
        // NO-OP
        nil
    }

    var asArm64CpuSubType: String? {
        switch self {
        case .cpuSubTypeArm64All: return "ALL"
        case .cpuSubTypeArm64V8: return "V8"
        case .cpuSubTypeArm64E: return "E"
        default: return nil
        }
    }
}
