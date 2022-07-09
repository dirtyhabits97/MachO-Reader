import Foundation

public struct DyldChainedPtrBindOrRebase {

    public let underlyingValue: UnderlyingValue

    let next: UInt32

    // TODO: split this into different blocks, similar to loadcommand type implementation
    init?(from data: Data, pointerFormat: DyldChainedSegmentInfo.PointerFormat) {
        if pointerFormat == .DYLD_CHAINED_PTR_ARM64E {

            let values = data.extract(UInt64.self).split(using: [62, 1, 1])
            let isBind = values[1] == 1
            let isAuth = values[2] == 1

            switch (isBind, isAuth) {
            case (true, true):
                break
            case (true, false):
                break
            case (false, true):
                let rebase = data.extract(DyldChainedPtrArm64eAuthRebase.self)
                underlyingValue = .arm64(.authRebase(rebase))
                next = rebase.next
            case (false, false):
                let rebase = data.extract(DyldChainedPtrArm64eRebase.self)
                underlyingValue = .arm64(.rebase(rebase))
                next = rebase.next
            }
            return
        }
        if [.DYLD_CHAINED_PTR_64, .DYLD_CHAINED_PTR_64_OFFSET].contains(pointerFormat) {
            let bind = data.extract(DyldChainedPtr64Bind.self)

            if bind.bind {
                underlyingValue = .bind64(data.extract(DyldChainedPtr64Bind.self))
            } else {
                underlyingValue = .rebase64(data.extract(DyldChainedPtr64Rebase.self))
            }

            next = UInt32(bind.next)
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_ARM64E_USERLAND24 {
            // TODO: handle this scenario
        }
        if [.DYLD_CHAINED_PTR_64_KERNEL_CACHE, .DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE].contains(pointerFormat) {
            let rebase = data.extract(DyldChainedPtr64KernelCacheRebase.self)
            underlyingValue = .kernelCacheRebase(rebase)
            next = rebase.next
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_32 {
            let bind = data.extract(DyldChainedPtr32Bind.self)

            if bind.bind {
                underlyingValue = .bind32(data.extract(DyldChainedPtr32Bind.self))
            } else {
                underlyingValue = .rebase32(data.extract(DyldChainedPtr32Rebase.self))
            }

            next = bind.next
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_32_CACHE {
            let rebase = data.extract(DyldChainedPtr32CacheRebase.self)
            underlyingValue = .cacheRebase(rebase)
            next = rebase.next
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_32_FIRMWARE {
            let rebase = data.extract(DyldChainedPtr32FirmwareRebase.self)
            underlyingValue = .firmwareRebase(rebase)
            next = rebase.next
            return
        }
        return nil
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
        case rebase(DyldChainedPtrArm64eRebase)
        case authRebase(DyldChainedPtrArm64eAuthRebase)
    }
}

// MARK: - Models

public struct DyldChainedPtr64Bind: CustomExtractable {

    public let ordinal: UInt64
    public let addend: UInt64
    public let reserved: UInt64
    public let next: UInt64
    public let bind: Bool

    init(_ rawValue: dyld_chained_ptr_64_bind) {
        let values = rawValue.split(using: [24, 8, 19, 12, 1])
        ordinal = values[0]
        addend = values[1]
        reserved = values[2]
        next = values[3]
        bind = values[4] == 1
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_64_bind.self))
    }
}

public struct DyldChainedPtr32Bind: CustomExtractable {

    public let ordinal: UInt32
    public let addend: UInt8
    public let next: UInt32
    public let bind: Bool

    init(_ rawValue: dyld_chained_ptr_32_bind) {
        let values = rawValue.split(using: [20, 6, 5, 1])
        ordinal = values[0]
        addend = UInt8(truncatingIfNeeded: values[1])
        next = values[2]
        bind = values[3] == 1
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_32_bind.self))
    }
}

public struct DyldChainedPtr64Rebase: CustomExtractable {

    public let target: UInt64
    public let high8: UInt8
    public let reserved: UInt8
    public let next: UInt16
    public let bind: Bool

    init(_ rawValue: dyld_chained_ptr_64_rebase) {
        let values = rawValue.split(using: [36, 8, 7, 12, 1])
        target = values[0]
        high8 = UInt8(truncatingIfNeeded: values[1])
        reserved = UInt8(truncatingIfNeeded: values[2])
        next = UInt16(truncatingIfNeeded: values[3])
        bind = values[4] == 1
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_64_rebase.self))
    }
}

public struct DyldChainedPtr32Rebase: CustomExtractable {

    public let target: UInt32
    public let next: UInt32
    public let bind: Bool

    init(_ rawValue: dyld_chained_ptr_32_rebase) {
        let values = rawValue.split(using: [26, 5, 1])
        target = values[0]
        next = values[1]
        bind = values[2] == 1
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_32_rebase.self))
    }
}

public struct DyldChainedPtrArm64eRebase: CustomExtractable {

    public let target: UInt64
    public let high8: UInt8
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_rebase) {
        let values = rawValue.split(using: [43, 8, 11, 1, 1])
        target = values[0]
        high8 = UInt8(truncatingIfNeeded: values[1])
        next = UInt32(truncatingIfNeeded: values[2])
        bind = values[3] == 1
        auth = values[4] == 1

        assert(bind == false)
        assert(auth == false)
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_arm64e_rebase.self))
    }
}

public struct DyldChainedPtrArm64eAuthRebase: CustomExtractable {

    public let target: UInt32
    public let diversity: UInt16
    public let addrDiv: Bool
    public let key: UInt8
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_auth_rebase) {
        let values = rawValue.split(using: [32, 16, 1, 2, 11, 1, 1])
        target = UInt32(truncatingIfNeeded: values[0])
        diversity = UInt16(truncatingIfNeeded: values[1])
        addrDiv = values[2] == 1
        key = UInt8(truncatingIfNeeded: values[3])
        next = UInt32(truncatingIfNeeded: values[4])
        bind = values[5] == 1
        auth = values[6] == 1

        assert(bind == false)
        assert(auth == true)
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_arm64e_auth_rebase.self))
    }
}

public struct DyldChainedPtr64KernelCacheRebase: CustomExtractable {

    public let target: UInt32
    public let cacheLevel: UInt8
    public let diversity: UInt16
    public let addrDiv: UInt8
    public let key: UInt8
    public let next: UInt32
    public let isAuth: Bool

    init(_ rawValue: dyld_chained_ptr_64_kernel_cache_rebase) {
        let values = rawValue.split(using: [30, 2, 16, 1, 2, 12, 1])
        target = UInt32(truncatingIfNeeded: values[0])
        cacheLevel = UInt8(truncatingIfNeeded: values[1])
        diversity = UInt16(truncatingIfNeeded: values[2])
        addrDiv = UInt8(truncatingIfNeeded: values[3])
        key = UInt8(truncatingIfNeeded: values[4])
        next = UInt32(truncatingIfNeeded: values[5])
        isAuth = values[6] == 1
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_64_kernel_cache_rebase.self))
    }
}

public struct DyldChainedPtr32CacheRebase: CustomExtractable {

    public let target: UInt32
    public let next: UInt32

    init(_ rawValue: dyld_chained_ptr_32_cache_rebase) {
        let values = rawValue.split(using: [30, 2])
        target = values[0]
        next = values[1]
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_32_cache_rebase.self))
    }
}

public struct DyldChainedPtr32FirmwareRebase: CustomExtractable {

    public let target: UInt32
    public let next: UInt32

    init(_ rawValue: dyld_chained_ptr_32_firmware_rebase) {
        let values = rawValue.split(using: [26, 6])
        target = values[0]
        next = values[1]
    }

    init(from data: Data) {
        self.init(data.extract(dyld_chained_ptr_32_firmware_rebase.self))
    }
}
