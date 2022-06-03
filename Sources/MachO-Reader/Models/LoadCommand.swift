import Foundation
import MachO

let kByteSwapOrder = NXByteOrder(0)

@dynamicMemberLookup
struct LoadCommand {

    // MARK: - Properties

    private let underlyingValue: load_command

    let data: Data
    let isSwapped: Bool

    // MARK: - Lifecycle

    init(from data: Data, isSwapped: Bool) {
        var loadCommand = data.extract(load_command.self)

        if isSwapped {
            swap_load_command(&loadCommand, kByteSwapOrder)
        }

        self.data = data
        self.isSwapped = isSwapped
        self.underlyingValue = loadCommand
    }

    // MARK: - Methods

    func commandType() -> LoadCommandType {
        LoadCommandType(from: self)
    }

    subscript<T>(dynamicMember keyPath: KeyPath<load_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}
