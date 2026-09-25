import Foundation
import MachO

/**
 * The rpath_command contains a path which at runtime should be added to
 * the current run path used to find @rpath prefixed dylibs.
 */
public struct RpathCommand: LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public let path: String

    // MARK: - Lifecycle

    /// struct rpath_command {
    ///     uint32_t	 cmd;		/* LC_RPATH */
    ///     uint32_t	 cmdsize;	/* includes string */
    ///     union lc_str path;		/* path to add to run path */
    /// };
    init(from loadCommand: LoadCommand) throws {
        var rpathCommand = try loadCommand.data.decode(rpath_command.self)

        if loadCommand.isSwapped {
            swap_rpath_command(&rpathCommand, kByteSwapOrder)
        }

        self.loadCommand = loadCommand
        path = try loadCommand.data.decodeString(
            maxLength: Int(rpathCommand.cmdsize) - Int(rpathCommand.path.offset),
            at: Int(rpathCommand.path.offset),
        )
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
