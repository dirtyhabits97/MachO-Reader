import Foundation
import MachO

/**
 * A dynamically linked shared library (filetype == MH_DYLIB in the mach header)
 * contains a dylib_command (cmd == LC_ID_DYLIB) to identify the library.
 * An object that uses a dynamically linked shared library also contains a
 * dylib_command (cmd == LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, or
 * LC_REEXPORT_DYLIB) for each library it uses.
 */
public struct DylibCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public var cmd: Cmd { loadCommand.cmd }

    public let dylib: Dylib

    // MARK: - Init

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(DylibCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(DylibCommand.allowedCmds)")

        var dylibCommand = loadCommand.data.extract(dylib_command.self)

        if loadCommand.isSwapped {
            swap_dylib_command(&dylibCommand, kByteSwapOrder)
        }

        self.init(dylibCommand, loadCommand: loadCommand)
    }

    // struct dylib_command {
    //   uint32_t	cmd;		/* LC_ID_DYLIB, LC_LOAD_{,WEAK_}DYLIB,
    //              LC_REEXPORT_DYLIB */
    //   uint32_t	cmdsize;	/* includes pathname string */
    //   struct dylib	dylib;		/* the library identification */
    // };
    init(_ dylibCommand: dylib_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand
        dylib = Dylib(command: dylibCommand, data: loadCommand.data)
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [.idDylib, .loadDylib, .loadWeakDylib, .reexportDylib]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .dylibCommand(DylibCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}

// MARK: - Helpers

public extension DylibCommand {

    /**
     * Dynamicly linked shared libraries are identified by two things. The
     * pathname (the name of the library as found for execution), and the
     * compatibility version number.  The pathname must match and the compatibility
     * number in the user of the library must be greater than or equal to the
     * library being used.  The time stamp is used to record the time a library was
     * built and copied into user so it can be use to determined if the library used
     * at runtime is exactly the same as used to built the program.
     */
    struct Dylib {

        public let name: String
        let timestamp: Date
        let currentVersion: SemanticVersion
        let compatibilityVersion: SemanticVersion

        // struct dylib {
        //     union lc_str  name;			/* library's path name */
        //     uint32_t timestamp;			/* library's build time stamp */
        //     uint32_t current_version;		/* library's current version number */
        //     uint32_t compatibility_version;	/* library's compatibility vers number*/
        // };
        init(command: dylib_command, data: Data) {
            let offset = Int(command.dylib.name.offset)
            let data = data.advanced(by: offset)
            let length = Int(command.cmdsize) - offset

            name = String(data: data[..<length], encoding: .utf8)?
                .trimmingCharacters(in: .controlCharacters)
                ?? ""
            timestamp = Date(timeIntervalSince1970: Double(command.dylib.timestamp))
            currentVersion = SemanticVersion(command.dylib.current_version)
            compatibilityVersion = SemanticVersion(command.dylib.compatibility_version)
        }
    }
}
