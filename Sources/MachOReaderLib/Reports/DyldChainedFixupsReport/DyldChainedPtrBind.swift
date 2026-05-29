import Foundation

public struct DyldChainedPtrBindOrRebase {

    public let underlyingValue: UnderlyingValue

    let next: UInt32

    init?(from data: Data, pointerFormat: DyldChainedSegmentInfo.PointerFormat) {
        let decoded: (UnderlyingValue, UInt32)?
        switch pointerFormat {
        case .DYLD_CHAINED_PTR_ARM64E:
            decoded = Self.decodeArm64(from: data, userland24: false)
        case .DYLD_CHAINED_PTR_ARM64E_USERLAND24:
            decoded = Self.decodeArm64(from: data, userland24: true)
        case .DYLD_CHAINED_PTR_64, .DYLD_CHAINED_PTR_64_OFFSET:
            decoded = Self.decode64(from: data)
        case .DYLD_CHAINED_PTR_64_KERNEL_CACHE, .DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE:
            decoded = Self.decodeKernelCache(from: data)
        case .DYLD_CHAINED_PTR_32:
            decoded = Self.decode32(from: data)
        case .DYLD_CHAINED_PTR_32_CACHE:
            decoded = Self.decode32Cache(from: data)
        case .DYLD_CHAINED_PTR_32_FIRMWARE:
            decoded = Self.decode32Firmware(from: data)
        default:
            decoded = nil
        }

        guard let decoded else { return nil }
        underlyingValue = decoded.0
        next = decoded.1
    }

    // MARK: - Per-format decoders

    /// ARM64E and ARM64E_USERLAND24 share the same bind/rebase discrimination — the
    /// top two bits are `bind` and `auth`. Only the bind layouts differ: USERLAND24
    /// binds carry a 24-bit ordinal (the dedicated `*_bind24` layouts).
    private static func decodeArm64(from data: Data, userland24: Bool) -> (UnderlyingValue, UInt32) {
        let values = data.extract(UInt64.self).split(using: [62, 1, 1])
        let isBind = values[1] == 1
        let isAuth = values[2] == 1

        switch (isBind, isAuth) {
        case (true, true):
            if userland24 {
                let bind = data.extract(DyldChainedPtrArm64eAuthBind24.self)
                return (.arm64(.authBind24(bind)), bind.next)
            }
            let bind = data.extract(DyldChainedPtrArm64eAuthBind.self)
            return (.arm64(.authBind(bind)), bind.next)
        case (true, false):
            if userland24 {
                let bind = data.extract(DyldChainedPtrArm64eBind24.self)
                return (.arm64(.bind24(bind)), bind.next)
            }
            let bind = data.extract(DyldChainedPtrArm64eBind.self)
            return (.arm64(.bind(bind)), bind.next)
        case (false, true):
            let rebase = data.extract(DyldChainedPtrArm64eAuthRebase.self)
            return (.arm64(.authRebase(rebase)), rebase.next)
        case (false, false):
            let rebase = data.extract(DyldChainedPtrArm64eRebase.self)
            return (.arm64(.rebase(rebase)), rebase.next)
        }
    }

    private static func decode64(from data: Data) -> (UnderlyingValue, UInt32) {
        let bind = data.extract(DyldChainedPtr64Bind.self)
        let value: UnderlyingValue = bind.bind
            ? .bind64(data.extract(DyldChainedPtr64Bind.self))
            : .rebase64(data.extract(DyldChainedPtr64Rebase.self))
        return (value, UInt32(bind.next))
    }

    private static func decode32(from data: Data) -> (UnderlyingValue, UInt32) {
        let bind = data.extract(DyldChainedPtr32Bind.self)
        let value: UnderlyingValue = bind.bind
            ? .bind32(data.extract(DyldChainedPtr32Bind.self))
            : .rebase32(data.extract(DyldChainedPtr32Rebase.self))
        return (value, bind.next)
    }

    private static func decodeKernelCache(from data: Data) -> (UnderlyingValue, UInt32) {
        let rebase = data.extract(DyldChainedPtr64KernelCacheRebase.self)
        return (.kernelCacheRebase(rebase), rebase.next)
    }

    private static func decode32Cache(from data: Data) -> (UnderlyingValue, UInt32) {
        let rebase = data.extract(DyldChainedPtr32CacheRebase.self)
        return (.cacheRebase(rebase), rebase.next)
    }

    private static func decode32Firmware(from data: Data) -> (UnderlyingValue, UInt32) {
        let rebase = data.extract(DyldChainedPtr32FirmwareRebase.self)
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
