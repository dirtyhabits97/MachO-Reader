import Foundation

public struct DyldChainedPtrBindOrRebase {

    public let underlyingValue: UnderlyingValue

    let next: UInt32

    init?(from data: Data, pointerFormat: DyldChainedSegmentInfo.PointerFormat) throws {
        let decoded: (UnderlyingValue, UInt32)? = switch pointerFormat {
        case .DYLD_CHAINED_PTR_ARM64E:
            try Self.decodeArm64(from: data, userland24: false)
        case .DYLD_CHAINED_PTR_ARM64E_USERLAND24:
            try Self.decodeArm64(from: data, userland24: true)
        case .DYLD_CHAINED_PTR_64, .DYLD_CHAINED_PTR_64_OFFSET:
            try Self.decode64(from: data)
        case .DYLD_CHAINED_PTR_64_KERNEL_CACHE, .DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE:
            try Self.decodeKernelCache(from: data)
        case .DYLD_CHAINED_PTR_32:
            try Self.decode32(from: data)
        case .DYLD_CHAINED_PTR_32_CACHE:
            try Self.decode32Cache(from: data)
        case .DYLD_CHAINED_PTR_32_FIRMWARE:
            try Self.decode32Firmware(from: data)
        default:
            nil
        }

        guard let decoded else { return nil }
        underlyingValue = decoded.0
        next = decoded.1
    }

    // MARK: - Per-format decoders

    /// Decodes a `BinaryDecodable` pointer model from the start of `data`.
    private static func decode<T: BinaryDecodable>(_ type: T.Type, from data: Data) throws -> T {
        try BinaryDecoder(data: data).decode(type, at: 0)
    }

    /// ARM64E and ARM64E_USERLAND24 share the same bind/rebase discrimination — the
    /// top two bits are `bind` and `auth`. Only the bind layouts differ: USERLAND24
    /// binds carry a 24-bit ordinal (the dedicated `*_bind24` layouts).
    private static func decodeArm64(from data: Data, userland24: Bool) throws -> (UnderlyingValue, UInt32) {
        let values = try data.decode(UInt64.self).split(using: [62, 1, 1])
        let isBind = values[1] == 1
        let isAuth = values[2] == 1

        switch (isBind, isAuth) {
        case (true, true):
            if userland24 {
                let bind = try decode(DyldChainedPtrArm64eAuthBind24.self, from: data)
                return (.arm64(.authBind24(bind)), bind.next)
            }
            let bind = try decode(DyldChainedPtrArm64eAuthBind.self, from: data)
            return (.arm64(.authBind(bind)), bind.next)
        case (true, false):
            if userland24 {
                let bind = try decode(DyldChainedPtrArm64eBind24.self, from: data)
                return (.arm64(.bind24(bind)), bind.next)
            }
            let bind = try decode(DyldChainedPtrArm64eBind.self, from: data)
            return (.arm64(.bind(bind)), bind.next)
        case (false, true):
            let rebase = try decode(DyldChainedPtrArm64eAuthRebase.self, from: data)
            return (.arm64(.authRebase(rebase)), rebase.next)
        case (false, false):
            let rebase = try decode(DyldChainedPtrArm64eRebase.self, from: data)
            return (.arm64(.rebase(rebase)), rebase.next)
        }
    }

    private static func decode64(from data: Data) throws -> (UnderlyingValue, UInt32) {
        let bind = try decode(DyldChainedPtr64Bind.self, from: data)
        let value: UnderlyingValue = try bind.bind
            ? .bind64(decode(DyldChainedPtr64Bind.self, from: data))
            : .rebase64(decode(DyldChainedPtr64Rebase.self, from: data))
        return (value, UInt32(bind.next))
    }

    private static func decode32(from data: Data) throws -> (UnderlyingValue, UInt32) {
        let bind = try decode(DyldChainedPtr32Bind.self, from: data)
        let value: UnderlyingValue = try bind.bind
            ? .bind32(decode(DyldChainedPtr32Bind.self, from: data))
            : .rebase32(decode(DyldChainedPtr32Rebase.self, from: data))
        return (value, bind.next)
    }

    private static func decodeKernelCache(from data: Data) throws -> (UnderlyingValue, UInt32) {
        let rebase = try decode(DyldChainedPtr64KernelCacheRebase.self, from: data)
        return (.kernelCacheRebase(rebase), rebase.next)
    }

    private static func decode32Cache(from data: Data) throws -> (UnderlyingValue, UInt32) {
        let rebase = try decode(DyldChainedPtr32CacheRebase.self, from: data)
        return (.cacheRebase(rebase), rebase.next)
    }

    private static func decode32Firmware(from data: Data) throws -> (UnderlyingValue, UInt32) {
        let rebase = try decode(DyldChainedPtr32FirmwareRebase.self, from: data)
        return (.firmwareRebase(rebase), rebase.next)
    }
}

public extension DyldChainedPtrBindOrRebase {

    enum UnderlyingValue {

        case arm64(Arm64)
        case bind32(DyldChainedPtr32Bind)
        case bind64(DyldChainedPtr64Bind)
        case rebase32(DyldChainedPtr32Rebase)
        case rebase64(DyldChainedPtr64Rebase)
        case kernelCacheRebase(DyldChainedPtr64KernelCacheRebase)
        case cacheRebase(DyldChainedPtr32CacheRebase)
        case firmwareRebase(DyldChainedPtr32FirmwareRebase)
    }

    enum Arm64 {

        case bind(DyldChainedPtrArm64eBind)
        case rebase(DyldChainedPtrArm64eRebase)
        case authBind(DyldChainedPtrArm64eAuthBind)
        case authRebase(DyldChainedPtrArm64eAuthRebase)
        case bind24(DyldChainedPtrArm64eBind24)
        case authBind24(DyldChainedPtrArm64eAuthBind24)
    }
}
