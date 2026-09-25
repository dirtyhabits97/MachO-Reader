import Foundation

// Swift models for the raw C dyld_chained_ptr_* bitfield structs.
// Each maps a fixed-width integer into its named bit fields via split(using:).

public struct DyldChainedPtr64Bind: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_64_bind.self))
    }
}

public struct DyldChainedPtr32Bind: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_32_bind.self))
    }
}

public struct DyldChainedPtr64Rebase: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_64_rebase.self))
    }
}

public struct DyldChainedPtr32Rebase: BinaryDecodable {

    public let target: UInt32
    public let next: UInt32
    public let bind: Bool

    init(_ rawValue: dyld_chained_ptr_32_rebase) {
        let values = rawValue.split(using: [26, 5, 1])
        target = values[0]
        next = values[1]
        bind = values[2] == 1
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_32_rebase.self))
    }
}

public struct DyldChainedPtrArm64eRebase: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_rebase.self))
    }
}

public struct DyldChainedPtrArm64eAuthRebase: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_auth_rebase.self))
    }
}

public struct DyldChainedPtrArm64eBind: BinaryDecodable {

    public let ordinal: UInt16
    public let zero: UInt16
    public let addend: UInt32
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_bind) {
        let values = rawValue.split(using: [16, 16, 19, 11, 1, 1])
        ordinal = UInt16(truncatingIfNeeded: values[0])
        zero = UInt16(truncatingIfNeeded: values[1])
        addend = UInt32(truncatingIfNeeded: values[2])
        next = UInt32(truncatingIfNeeded: values[3])
        bind = values[4] == 1
        auth = values[5] == 1

        assert(bind == true)
        assert(auth == false)
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_bind.self))
    }
}

public struct DyldChainedPtrArm64eAuthBind: BinaryDecodable {

    public let ordinal: UInt16
    public let zero: UInt16
    public let diversity: UInt16
    public let addrDiv: Bool
    public let key: UInt8
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_auth_bind) {
        let values = rawValue.split(using: [16, 16, 16, 1, 2, 11, 1, 1])
        ordinal = UInt16(truncatingIfNeeded: values[0])
        zero = UInt16(truncatingIfNeeded: values[1])
        diversity = UInt16(truncatingIfNeeded: values[2])
        addrDiv = values[3] == 1
        key = UInt8(truncatingIfNeeded: values[4])
        next = UInt32(truncatingIfNeeded: values[5])
        bind = values[6] == 1
        auth = values[7] == 1

        assert(bind == true)
        assert(auth == true)
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_auth_bind.self))
    }
}

public struct DyldChainedPtrArm64eBind24: BinaryDecodable {

    public let ordinal: UInt32
    public let zero: UInt8
    public let addend: UInt32
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_bind24) {
        let values = rawValue.split(using: [24, 8, 19, 11, 1, 1])
        ordinal = UInt32(truncatingIfNeeded: values[0])
        zero = UInt8(truncatingIfNeeded: values[1])
        addend = UInt32(truncatingIfNeeded: values[2])
        next = UInt32(truncatingIfNeeded: values[3])
        bind = values[4] == 1
        auth = values[5] == 1

        assert(bind == true)
        assert(auth == false)
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_bind24.self))
    }
}

public struct DyldChainedPtrArm64eAuthBind24: BinaryDecodable {

    public let ordinal: UInt32
    public let zero: UInt8
    public let diversity: UInt16
    public let addrDiv: Bool
    public let key: UInt8
    public let next: UInt32
    public let bind: Bool
    public let auth: Bool

    init(_ rawValue: dyld_chained_ptr_arm64e_auth_bind24) {
        let values = rawValue.split(using: [24, 8, 16, 1, 2, 11, 1, 1])
        ordinal = UInt32(truncatingIfNeeded: values[0])
        zero = UInt8(truncatingIfNeeded: values[1])
        diversity = UInt16(truncatingIfNeeded: values[2])
        addrDiv = values[3] == 1
        key = UInt8(truncatingIfNeeded: values[4])
        next = UInt32(truncatingIfNeeded: values[5])
        bind = values[6] == 1
        auth = values[7] == 1

        assert(bind == true)
        assert(auth == true)
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_arm64e_auth_bind24.self))
    }
}

public struct DyldChainedPtr64KernelCacheRebase: BinaryDecodable {

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

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_64_kernel_cache_rebase.self))
    }
}

public struct DyldChainedPtr32CacheRebase: BinaryDecodable {

    public let target: UInt32
    public let next: UInt32

    init(_ rawValue: dyld_chained_ptr_32_cache_rebase) {
        let values = rawValue.split(using: [30, 2])
        target = values[0]
        next = values[1]
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_32_cache_rebase.self))
    }
}

public struct DyldChainedPtr32FirmwareRebase: BinaryDecodable {

    public let target: UInt32
    public let next: UInt32

    init(_ rawValue: dyld_chained_ptr_32_firmware_rebase) {
        let values = rawValue.split(using: [26, 6])
        target = values[0]
        next = values[1]
    }

    public init(from decoder: inout BinaryDecoder) throws {
        try self.init(decoder.decode(dyld_chained_ptr_32_firmware_rebase.self))
    }
}
