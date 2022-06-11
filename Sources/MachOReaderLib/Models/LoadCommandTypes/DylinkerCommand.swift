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
public struct DylinkerCommand {

    // MARK: - Properties

    // struct dylinker_command {
    //   uint32_t	cmd;		/* LC_ID_DYLINKER, LC_LOAD_DYLINKER or
    //              LC_DYLD_ENVIRONMENT */
    //   uint32_t	cmdsize;	/* includes pathname string */
    //   union lc_str    name;		/* dynamic linker's path name */
    // };
    private let underlyingValue: dylinker_command

    public let name: String

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var dylinkerCommand = loadCommand.data.extract(dylinker_command.self)

        if loadCommand.isSwapped {
            swap_dylinker_command(&dylinkerCommand, kByteSwapOrder)
        }

        let offset = Int(dylinkerCommand.name.offset)
        let data = loadCommand.data.advanced(by: offset)
        let length = Int(dylinkerCommand.cmdsize) - offset

        underlyingValue = dylinkerCommand
        name = String(data: data[..<length], encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
            ?? ""
    }
}

extension DylinkerCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .dylinkerCommand(DylinkerCommand(from: loadCommand))
    }
}

extension DylinkerCommand: CustomStringConvertible {

    // TODO: delete this
    public var description: String { name }
}
