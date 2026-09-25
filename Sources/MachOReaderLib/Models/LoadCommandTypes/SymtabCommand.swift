import Foundation
import MachO

/**
 * The symtab_command contains the offsets and sizes of the link-edit 4.3BSD
 * "stab" style symbol table information as described in the header files
 * <nlist.h> and <stab.h>.
 */
@dynamicMemberLookup
public struct SymtabCommand: LoadCommandTransformable {

    // MARK: - Properties

    private let underlyingValue: symtab_command
    private let loadCommand: LoadCommand

    // MARK: - Lifecycle

    /// struct symtab_command {
    ///   uint32_t	cmd;		/* LC_SYMTAB */
    ///   uint32_t	cmdsize;	/* sizeof(struct symtab_command) */
    ///   uint32_t	symoff;		/* symbol table offset */
    ///   uint32_t	nsyms;		/* number of symbol table entries */
    ///   uint32_t	stroff;		/* string table offset */
    ///   uint32_t	strsize;	/* string table size in bytes */
    /// };
    init(from loadCommand: LoadCommand) throws {
        var symtabCommand = try loadCommand.data.decode(symtab_command.self)

        if loadCommand.isSwapped {
            swap_symtab_command(&symtabCommand, kByteSwapOrder)
        }

        self.loadCommand = loadCommand
        underlyingValue = symtabCommand
    }

    // MARK: - Methods

    public subscript<T>(dynamicMember keyPath: KeyPath<symtab_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
