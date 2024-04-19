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
public struct DyldInfoCommand: LoadCommandModel {

    // MARK: - Properties

    private let loadCommand: LoadCommand
    private let underlyingValue: dyld_info_command

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(DyldInfoCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(DyldInfoCommand.allowedCmds)")

        var dyldInfoCommand = loadCommand.data.extract(dyld_info_command.self)

        if loadCommand.isSwapped {
            swap_dyld_info_command(&dyldInfoCommand, kByteSwapOrder)
        }

        self.init(dyldInfoCommand, loadCommand: loadCommand)
    }

    private init(_ dyldInfoCommand: dyld_info_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand
        underlyingValue = dyldInfoCommand
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<dyld_info_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [.dyldInfo, .dyldInfoOnly]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .dyldInfoCommand(DyldInfoCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
