import Foundation
import MachO

/**
 * A program that uses a dynamic linker contains a dylinker_command to identify
 * the name of the dynamic linker (LC_LOAD_DYLINKER).  And a dynamic linker
 * contains a dylinker_command to identify the dynamic linker (LC_ID_DYLINKER).
 * A file can have at most one of these.
 * This struct is also used for the LC_DYLD_ENVIRONMENT load command and
 * contains string for dyld to treat like environment variable.
 */
public struct DylinkerCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    // struct dylinker_command {
    //   uint32_t	cmd;		/* LC_ID_DYLINKER, LC_LOAD_DYLINKER or
    //              LC_DYLD_ENVIRONMENT */
    //   uint32_t	cmdsize;	/* includes pathname string */
    //   union lc_str    name;		/* dynamic linker's path name */
    // };
    private let underlyingValue: dylinker_command
    private let loadCommand: LoadCommand
    public let name: String

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(DylinkerCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(DylinkerCommand.allowedCmds)")

        var dylinkerCommand = loadCommand.data.extract(dylinker_command.self)

        if loadCommand.isSwapped {
            swap_dylinker_command(&dylinkerCommand, kByteSwapOrder)
        }

        self.init(dylinkerCommand, loadCommand: loadCommand)
    }

    private init(_ dylinkerCommand: dylinker_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        let offset = Int(dylinkerCommand.name.offset)
        let data = loadCommand.data.advanced(by: offset)
        let length = Int(dylinkerCommand.cmdsize) - offset

        underlyingValue = dylinkerCommand
        name = String(data: data[..<length], encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
            ?? ""
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [.idDylinker, .loadDylinker, .dyldEnvironment]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .dylinkerCommand(DylinkerCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
