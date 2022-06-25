import Foundation

public struct DyldChainedImport {

    public let libOrdinal: UInt8
    public let isWeakImport: Bool
    public let nameOffset: UInt32

    public internal(set) var dylibName: String?
    public internal(set) var symbolName: String?

    init(_ chainedImport: dyld_chained_import) {
        let values = chainedImport.split(using: [8, 1, 23])
        libOrdinal = UInt8(truncatingIfNeeded: values[0])
        isWeakImport = values[1] == 1
        nameOffset = values[2]
    }
}

// TODO: move this somewhere
extension String.SubSequence {

    func toString() -> String {
        String(self)
    }
}
