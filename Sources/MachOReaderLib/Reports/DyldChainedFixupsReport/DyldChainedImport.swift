import Foundation

@dynamicMemberLookup
struct DyldChainedImport {

    private let underlyingValue: dyld_chained_import
    var dylibName: String?
    var symbolName: String?

    init(_ underlyingValue: dyld_chained_import) {
        self.underlyingValue = underlyingValue
    }

    subscript<T>(dynamicMember keyPath: KeyPath<dyld_chained_import, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}

extension String.SubSequence {

    func toString() -> String {
        String(self)
    }
}
