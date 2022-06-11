import Foundation
import MachO

/**
 * The entry_point_command is a replacement for thread_command.
 * It is used for main executables to specify the location (file offset)
 * of main().  If -stack_size was used at link time, the stacksize
 * field will contain the stack size need for the main thread.
 */
@dynamicMemberLookup
public struct EntryPointCommand: LoadCommandTypeRepresentable {

    // MARK: - Properties

    // struct entry_point_command {
    //     uint32_t  cmd;	/* LC_MAIN only used in MH_EXECUTE filetypes */
    //     uint32_t  cmdsize;	/* 24 */
    //     uint64_t  entryoff;	/* file (__TEXT) offset of main() */
    //     uint64_t  stacksize;/* if not zero, initial stack size */
    // };
    private let underlyingValue: entry_point_command

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(EntryPointCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(EntryPointCommand.allowedCmds)")

        var entryPointCommand = loadCommand.data.extract(entry_point_command.self)

        if loadCommand.isSwapped {
            swap_entry_point_command(&entryPointCommand, kByteSwapOrder)
        }

        underlyingValue = entryPointCommand
    }

    // MARK: - Methods

    public subscript<T>(dynamicMember keyPath: KeyPath<entry_point_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> { [.main] }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .entryPointCommand(EntryPointCommand(from: loadCommand))
    }
}
