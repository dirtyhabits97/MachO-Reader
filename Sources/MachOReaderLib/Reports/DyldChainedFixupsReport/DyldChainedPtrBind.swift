import Foundation

enum DyldChainedPtrBindOrRebase {

    case bind32(dyld_chained_ptr_32_bind)
    case bind64(dyld_chained_ptr_64_bind)
    case rebase32(dyld_chained_ptr_32_rebase)
    case rebase64(dyld_chained_ptr_64_rebase)
}

// TODO: reorganize this next to the CModels. Somethng like Swift/PrettyModels

struct DyldChainedPtrBind {

    // MARK: - Properties

    private let underlyingValue: UnderlyingValue

    // MARK: - Lifecycle

    init(_ rawValue: dyld_chained_ptr_32_bind) {
        underlyingValue = .b32(rawValue)
    }

    init(_ rawValue: dyld_chained_ptr_64_bind) {
        underlyingValue = .b64(rawValue)
    }
}

extension DyldChainedPtrBind {

    enum UnderlyingValue {
        case b32(dyld_chained_ptr_32_bind)
        case b64(dyld_chained_ptr_64_bind)
    }
}

struct DyldChainedPtrRebase {

    // MARK: - Properties

    private let underlyingValue: UnderlyingValue

    // MARK: - Lifecycle

    init(_ rawValue: dyld_chained_ptr_32_rebase) {
        underlyingValue = .b32(rawValue)
    }

    init(_ rawValue: dyld_chained_ptr_64_rebase) {
        underlyingValue = .b64(rawValue)
    }
}

extension DyldChainedPtrRebase {

    enum UnderlyingValue {
        case b32(dyld_chained_ptr_32_rebase)
        case b64(dyld_chained_ptr_64_rebase)
    }
}
