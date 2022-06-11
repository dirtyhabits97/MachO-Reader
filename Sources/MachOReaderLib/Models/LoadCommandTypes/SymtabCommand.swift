import Foundation
import MachO

/**
 * The symtab_command contains the offsets and sizes of the link-edit 4.3BSD
 * "stab" style symbol table information as described in the header files
 * <nlist.h> and <stab.h>.
 */
@dynamicMemberLookup
public struct SymtabCommand {

    // MARK: - Properties

    // struct symtab_command {
    //   uint32_t	cmd;		/* LC_SYMTAB */
    //   uint32_t	cmdsize;	/* sizeof(struct symtab_command) */
    //   uint32_t	symoff;		/* symbol table offset */
    //   uint32_t	nsyms;		/* number of symbol table entries */
    //   uint32_t	stroff;		/* string table offset */
    //   uint32_t	strsize;	/* string table size in bytes */
    // };
    let underlyingValue: symtab_command

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var symtabCommand = loadCommand.data.extract(symtab_command.self)

        if loadCommand.isSwapped {
            swap_symtab_command(&symtabCommand, kByteSwapOrder)
        }

        underlyingValue = symtabCommand
    }

    // MARK: - Methods

    public subscript<T>(dynamicMember keyPath: KeyPath<symtab_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}

extension SymtabCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .symtabCommand(SymtabCommand(from: loadCommand))
    }
}

extension SymtabCommand: CustomStringConvertible {

    //   uint32_t	symoff;		/* symbol table offset */
    //   uint32_t	nsyms;		/* number of symbol table entries */
    //   uint32_t	stroff;		/* string table offset */
    //   uint32_t	strsize;	/* string table size in bytes */
    // TODO: delete this
    public var description: String {
        "symoff: \(self.symoff)   nsyms: \(self.nsyms)   stroff: \(self.stroff)   strsize: \(self.strsize)"
    }
}
