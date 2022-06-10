import Foundation
import MachO

/**
 * This is the second set of the symbolic information which is used to support
 * the data structures for the dynamically link editor.
 *
 * The original set of symbolic information in the symtab_command which contains
 * the symbol and string tables must also be present when this load command is
 * present.  When this load command is present the symbol table is organized
 * into three groups of symbols:
 *	local symbols (static and debugging symbols) - grouped by module
 *	defined external symbols - grouped by module (sorted by name if not lib)
 *	undefined external symbols (sorted by name if MH_BINDATLOAD is not set,
 *  and in order the were seen by the static linker if MH_BINDATLOAD is set)
 * In this load command there are offsets and counts to each of the three groups
 * of symbols.
 *
 * This load command contains a the offsets and sizes of the following new
 * symbolic information tables:
 *	table of contents
 *	module table
 *	reference symbol table
 *	indirect symbol table
 * The first three tables above (the table of contents, module table and
 * reference symbol table) are only present if the file is a dynamically linked
 * shared library.  For executable and object modules, which are files
 * containing only one module, the information that would be in these three
 * tables is determined as follows:
 * 	table of contents - the defined external symbols are sorted by name
 *	module table - the file contains only one module so everything in the file is part of the module.
 *	reference symbol table - is the defined and undefined external symbols
 *
 * For dynamically linked shared library files this load command also contains
 * offsets and sizes to the pool of relocation entries for all sections
 * separated into two groups:
 *	external relocation entries
 *	local relocation entries
 * For executable and object modules the relocation entries continue to hang
 * off the section structures.
 */
@dynamicMemberLookup
struct DysymtabCommand {

    // MARK: - Properties

    private let underlyingValue: dysymtab_command

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var dysymtabCommand = loadCommand.data.extract(dysymtab_command.self)

        if loadCommand.isSwapped {
            swap_dysymtab_command(&dysymtabCommand, kByteSwapOrder)
        }

        underlyingValue = dysymtabCommand
    }

    // MARK: - Methods

    subscript<T>(dynamicMember keyPath: KeyPath<dysymtab_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}

extension DysymtabCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .dysymtabCommand(DysymtabCommand(from: loadCommand))
    }
}

extension DysymtabCommand: CustomStringConvertible {

    var description: String {
        // swiftlint:disable:next line_length
        "nlocalsym: \(self.nlocalsym)  nextdefsym: \(self.nextdefsym)   nundefsym: \(self.nundefsym)   nindirectsyms: \(self.nindirectsyms)"
    }
}
