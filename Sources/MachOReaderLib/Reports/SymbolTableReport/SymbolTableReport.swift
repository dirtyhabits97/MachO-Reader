import Foundation
import MachO

/// Decodes the Mach-O symbol table (`LC_SYMTAB`) into `Symbol`s, resolving each
/// name from the string table — an `nm`-style view of the binary.
public final class SymbolTableReport {

    // MARK: - Properties

    let file: MachOFile

    public let symtab: SymtabCommand
    public private(set) var symbols: [Symbol] = []

    // MARK: - Lifecycle

    init(file: MachOFile) throws {
        guard let symtab = file.commands.getSymtabCommand() else {
            throw MachOFileError.missingSymbolTable
        }
        self.file = file
        self.symtab = symtab

        symbols = try SymbolTableBuilder(file: file, symtab: symtab).symbols
    }
}

// MARK: - SymbolTableBuilder

/// Walks the `nsyms` fixed-size `nlist_64` entries at `symoff` and resolves each
/// name from the null-terminated string blob at `stroff`.
struct SymbolTableBuilder {

    let symbols: [Symbol]

    init(file: MachOFile, symtab: SymtabCommand) throws {
        // `file.base` is the start of the (slice's) mach_header, so symoff/stroff
        // — which are relative to it — can be used as direct offsets.
        let decoder = BinaryDecoder(data: file.base)

        let symoff = Int(symtab.symoff)
        let stroff = Int(symtab.stroff)
        let stride = MemoryLayout<nlist_64>.size

        var symbols: [Symbol] = []
        symbols.reserveCapacity(Int(symtab.nsyms))

        for index in 0 ..< Int(symtab.nsyms) {
            let nlist = try decoder.decode(nlist_64.self, at: symoff + index * stride)
            var symbol = Symbol(nlist)

            // n_strx == 0 is the convention for "no name".
            if symbol.stringTableIndex != 0 {
                symbol.name = try? decoder.decodeString(at: stroff + Int(symbol.stringTableIndex))
            }

            symbols.append(symbol)
        }

        self.symbols = symbols
    }
}
