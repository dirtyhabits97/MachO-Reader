import Foundation

public struct DyldChainedPtrBindOrRebase {

    // TODO: store real data here
    public let textToPrint: String

    // TODO: make this non-optional let.
    public private(set) var underlyingValue: UnderlyingValue?

    let next: UInt32

    init?(from data: Data, pointerFormat: DyldChainedSegmentInfo.PointerFormat) {
        if [.DYLD_CHAINED_PTR_64, .DYLD_CHAINED_PTR_64_OFFSET].contains(pointerFormat) {
            let bind = data.extract(dyld_chained_ptr_64_bind.self)

            if bind.bind {
                // let chainedImport = fixupsReport.imports[Int(bind.ordinal)]
                // let symbolName = chainedImport.symbolName ?? "no symbol"
                textToPrint = "BIND"
            } else {
                underlyingValue = .rebase64(data.extract(DyldChainedPtr64Rebase.self))
                textToPrint = "REBASE"
            }

            next = UInt32(bind.next)
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_32 {
            let bind = data.extract(DyldChainedPtr32Bind.self)

            if bind.bind {
                underlyingValue = .bind32(data.extract(DyldChainedPtr32Bind.self))
                textToPrint = "BIND"
            } else {
                underlyingValue = .rebase32(data.extract(DyldChainedPtr32Rebase.self))
                textToPrint = "REBASE"
            }

            next = bind.next
            return
        }
        return nil
    }
}

public extension DyldChainedPtrBindOrRebase {

    enum UnderlyingValue {

        case bind32(DyldChainedPtr32Bind)
        case rebase32(DyldChainedPtr32Rebase)
        case rebase64(DyldChainedPtr64Rebase)
    }
}

// MARK: - Models

public struct DyldChainedPtr32Bind: CustomExtractable {

    let ordinal: UInt32
    let addend: UInt8
    let next: UInt32
    let bind: Bool

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
