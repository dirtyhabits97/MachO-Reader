import Foundation

// Source: include/mach/machine.h
public struct CPUSubType: RawRepresentable, Equatable {

    // MARK: - Properties

    public let rawValue: UInt32

    // MARK: - Lifecycle

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: cpu_subtype_t) {
        self.rawValue = UInt32(bitPattern: rawValue)
    }

    // NOTE: Some of these have the same bitPattern / flags
    // We only know the exact subtype if the cpu type is also provided

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
        case .arm64:
            // Sometimes rawValue is masked with 0x80000000,
            // we can remove the mask and check
            return asArm64CpuSubType(self)
                ?? asArm64CpuSubType(unmasked(self, mask: UInt32(CPU_SUBTYPE_PTRAUTH_ABI)))
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

    func asArm64CpuSubType(_ cpuSubType: CPUSubType) -> String? {
        switch cpuSubType {
        case .cpuSubTypeArm64All: return "ALL"
        case .cpuSubTypeArm64V8: return "V8"
        case .cpuSubTypeArm64E: return "E"
        default: return nil
        }
    }

    private func unmasked(_ cpuSubType: CPUSubType, mask: UInt32) -> CPUSubType {
        CPUSubType(rawValue: cpuSubType.rawValue & ~mask)
    }
}
