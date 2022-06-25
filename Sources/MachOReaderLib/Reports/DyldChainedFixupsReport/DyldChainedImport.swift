import Foundation

public struct DyldChainedImport {

    public let libOrdinal: UInt8
    public let isWeakImport: Bool
    public let nameOffset: UInt32

    public internal(set) var dylibName: String?
    public internal(set) var symbolName: String?

    init(_ underlyingValue: dyld_chained_import) {
        libOrdinal = underlyingValue.libOrdinal
        isWeakImport = underlyingValue.isWeakImport
        nameOffset = underlyingValue.nameOffset
    }
}

// TODO: move this somewhere
extension String.SubSequence {

    func toString() -> String {
        String(self)
    }
}
