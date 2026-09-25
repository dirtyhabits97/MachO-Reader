import Foundation
import MachO

/**
 * The rpath_command contains a path which at runtime should be added to
 * the current run path used to find @rpath prefixed dylibs.
 */
public struct RpathCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public let path: String

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(RpathCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(RpathCommand.allowedCmds)")

        guard var rpathCommand = try? loadCommand.data.decode(rpath_command.self, at: 0) else {
            fatalError("Failed to decode rpath_command from data of size \(loadCommand.data.count)")
        }

        if loadCommand.isSwapped {
            swap_rpath_command(&rpathCommand, kByteSwapOrder)
        }

        self.init(rpathCommand, loadCommand: loadCommand)
    }

    /// struct rpath_command {
    ///     uint32_t	 cmd;		/* LC_RPATH */
    ///     uint32_t	 cmdsize;	/* includes string */
    ///     union lc_str path;		/* path to add to run path */
    /// };
    private init(_ rpathCommand: rpath_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        let offset = Int(rpathCommand.path.offset)
        let data = loadCommand.data.advanced(by: offset)
        let length = Int(rpathCommand.cmdsize) - offset

        path = String(data: data[..<length], encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
            ?? ""
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [.rpath]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .rpathCommand(RpathCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
