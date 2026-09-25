import Foundation
import MachO

/*
 * The dyld_info_command contains the file offsets and sizes of
 * the new compressed form of the information dyld needs to
 * load the image.  This information is used by dyld on Mac OS X
 * 10.6 and later.  All information pointed to by this command
 * is encoded using byte streams, so no endian swapping is needed
 * to interpret it.
 */

@dynamicMemberLookup
public struct DyldInfoCommand: LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand
    private let underlyingValue: dyld_info_command

    init(from loadCommand: LoadCommand) throws {
        var dyldInfoCommand = try loadCommand.data.decode(dyld_info_command.self)

        if loadCommand.isSwapped {
            swap_dyld_info_command(&dyldInfoCommand, kByteSwapOrder)
        }

        self.loadCommand = loadCommand
        underlyingValue = dyldInfoCommand
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<dyld_info_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
