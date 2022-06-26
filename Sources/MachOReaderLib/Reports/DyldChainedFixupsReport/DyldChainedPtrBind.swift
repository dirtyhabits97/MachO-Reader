import Foundation

public struct DyldChainedPtrBindOrRebase {

    // TODO: store real data here
    public let textToPrint: String

    let next: UInt32

    init?(from data: Data, pointerFormat: DyldChainedSegmentInfo.PointerFormat) {
        if [.DYLD_CHAINED_PTR_64, .DYLD_CHAINED_PTR_64_OFFSET].contains(pointerFormat) {
            let bind = data.extract(dyld_chained_ptr_64_bind.self)

            if bind.bind {
                // let chainedImport = fixupsReport.imports[Int(bind.ordinal)]
                // let symbolName = chainedImport.symbolName ?? "no symbol"
                textToPrint = "BIND"
            } else {
                // let rebase = data.extract(dyld_chained_ptr_64_rebase.self)
                textToPrint = "REBASE"
            }

            next = UInt32(bind.next)
            return
        }
        if pointerFormat == .DYLD_CHAINED_PTR_32 {
            let bind = data.extract(dyld_chained_ptr_32_bind.self)

            if bind.bind {
                textToPrint = "BIND"
            } else {
                // let rebase = data.extract(dyld_chained_ptr_32_rebase.self)
                textToPrint = "REBASE"
            }

            next = bind.next
            return
        }
        return nil
    }
}

// enum DyldChainedPtrBindOrRebase {

//     case bind32(dyld_chained_ptr_32_bind)
//     case bind64(dyld_chained_ptr_64_bind)
//     case rebase32(dyld_chained_ptr_32_rebase)
//     case rebase64(dyld_chained_ptr_64_rebase)
// }

// // TODO: reorganize this next to the CModels. Somethng like Swift/PrettyModels

// struct DyldChainedPtrBind {

//     // MARK: - Properties

//     private let underlyingValue: UnderlyingValue

//     // MARK: - Lifecycle

//     init(_ rawValue: dyld_chained_ptr_32_bind) {
//         underlyingValue = .b32(rawValue)
//     }

//     init(_ rawValue: dyld_chained_ptr_64_bind) {
//         underlyingValue = .b64(rawValue)
//     }
// }

// extension DyldChainedPtrBind {

//     enum UnderlyingValue {
//         case b32(dyld_chained_ptr_32_bind)
//         case b64(dyld_chained_ptr_64_bind)
//     }
// }

// struct DyldChainedPtrRebase {

//     // MARK: - Properties

//     private let underlyingValue: UnderlyingValue

//     // MARK: - Lifecycle

//     init(_ rawValue: dyld_chained_ptr_32_rebase) {
//         underlyingValue = .b32(rawValue)
//     }

//     init(_ rawValue: dyld_chained_ptr_64_rebase) {
//         underlyingValue = .b64(rawValue)
//     }
// }

// extension DyldChainedPtrRebase {

//     enum UnderlyingValue {
//         case b32(dyld_chained_ptr_32_rebase)
//         case b64(dyld_chained_ptr_64_rebase)
//     }
// }
