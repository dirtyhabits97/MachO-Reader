import Foundation

/*
 * Thread commands contain machine-specific data structures suitable for
 * use in the thread state primitives.  The machine specific data structures
 * follow the struct thread_command as follows.
 * Each flavor of machine specific data structure is preceded by an uint32_t
 * constant for the flavor of that data structure, an uint32_t that is the
 * count of uint32_t's of the size of the state data structure and then
 * the state data structure follows.  This triple may be repeated for many
 * flavors.  The constants for the flavors, counts and state data structure
 * definitions are expected to be in the header file <machine/thread_status.h>.
 * These machine specific data structures sizes must be multiples of
 * 4 bytes.  The cmdsize reflects the total size of the thread_command
 * and all of the sizes of the constants for the flavors, counts and state
 * data structures.
 *
 * For executable objects that are unix processes there will be one
 * thread_command (cmd == LC_UNIXTHREAD) created for it by the link-editor.
 * This is the same as a LC_THREAD, except that a stack is automatically
 * created (based on the shell's limit for the stack size).  Command arguments
 * and environment variables are copied onto that stack.
 */
// TODO: get more info from this
public struct ThreadCommand {

    // MARK: - Properties

    // struct thread_command {
    //   uint32_t	cmd;		/* LC_THREAD or  LC_UNIXTHREAD */
    //   uint32_t	cmdsize;	/* total size of this command */
    //   /* uint32_t flavor		   flavor of thread state */
    //   /* uint32_t count		   count of uint32_t's in thread state */
    //   /* struct XXX_thread_state state   thread state for this flavor */
    //   /* ... */
    // };
    private let underlyingValue: thread_command

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var threadCommand = loadCommand.data.extract(thread_command.self)

        if loadCommand.isSwapped {
            swap_thread_command(&threadCommand, kByteSwapOrder)
        }

        underlyingValue = threadCommand
    }
}

extension ThreadCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .threadCommand(ThreadCommand(from: loadCommand))
    }
}
