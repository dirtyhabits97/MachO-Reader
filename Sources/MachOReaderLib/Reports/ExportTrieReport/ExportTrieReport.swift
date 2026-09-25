import Foundation

/// Decodes the Mach-O export trie into `ExportedSymbol`s — an `nm -gU` /
/// `dyld_info -exports`-style view of what a binary exports.
///
/// The trie is read from `LC_DYLD_EXPORTS_TRIE` when present, falling back to
/// the `export_off`/`export_size` blob of `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY`
/// on older binaries.
public final class ExportTrieReport {

    // MARK: - Properties

    let file: MachOFile

    public let symbols: [ExportedSymbol]

    // MARK: - Lifecycle

    init(file: MachOFile) throws {
        self.file = file

        let (offset, size) = try Self.exportTrieRange(in: file)

        // `file.base` is the start of the (slice's) mach_header, so dataoff/export_off
        // — which are relative to it — can be used as direct offsets.
        let decoder = try BinaryDecoder(data: file.base).subdecoder(at: offset, length: size)

        symbols = try ExportTrieBuilder(decoder: decoder, trieSize: size).symbols
            .sorted { $0.name < $1.name }
    }

    // MARK: - Methods

    private static func exportTrieRange(in file: MachOFile) throws -> (offset: Int, size: Int) {
        if let trie = file.commands.getDyldExportsTrie() {
            return (Int(trie.dataoff), Int(trie.datasize))
        }

        if let dyldInfo = file.commands.getDyldInfoCommand() {
            return (Int(dyldInfo.export_off), Int(dyldInfo.export_size))
        }

        throw MachOFileError.missingExportTrie
    }
}

// MARK: - ExportTrieError

/// Errors from walking a malformed export trie.
enum ExportTrieError: Error, Equatable, CustomStringConvertible {

    /// A child edge pointed back at a node already on the current path.
    case cycleDetected(offset: Int)

    var description: String {
        switch self {
        case let .cycleDetected(offset):
            "Cycle detected in export trie at offset \(offset)."
        }
    }
}

// MARK: - ExportTrieBuilder

/// Walks the export trie depth-first, accumulating edge labels into symbol
/// names and decoding each terminal node's payload.
///
/// Trie format (dyld's `MachOLoaded.cpp` / the `EXPORT_SYMBOL_FLAGS_*` comment
/// in `<mach-o/loader.h>`): each node starts with a ULEB128 `terminalSize`. A
/// non-zero size marks the node as terminal, with a `flags` ULEB128 followed by
/// a flags-dependent payload (re-export, stub-and-resolver, or a plain
/// address). After skipping `terminalSize` bytes of terminal payload, a single
/// byte gives the child count, then each child is a C string edge label
/// followed by a ULEB128 offset (relative to the trie start) of the child node.
struct ExportTrieBuilder {

    let symbols: [ExportedSymbol]

    init(decoder: BinaryDecoder, trieSize: Int) throws {
        guard trieSize > 0 else {
            symbols = []
            return
        }

        var symbols: [ExportedSymbol] = []
        var visited = Set<Int>()

        try Self.walk(decoder, offset: 0, name: "", symbols: &symbols, visited: &visited)

        self.symbols = symbols
    }

    // MARK: - Walking

    private static func walk(
        _ decoder: BinaryDecoder,
        offset: Int,
        name: String,
        symbols: inout [ExportedSymbol],
        visited: inout Set<Int>,
    ) throws {
        guard visited.insert(offset).inserted else {
            throw ExportTrieError.cycleDetected(offset: offset)
        }

        let (terminalSize, terminalSizeLength) = try decoder.decodeULEB128(at: offset)
        var cursor = offset + terminalSizeLength

        if terminalSize > 0 {
            try symbols.append(makeSymbol(decoder, at: cursor, name: name))
        }
        cursor += Int(terminalSize)

        let childCount = try decoder.decode(UInt8.self, at: cursor)
        cursor += 1

        for _ in 0 ..< childCount {
            let edgeLabel = try decoder.decodeString(at: cursor)
            cursor += edgeLabel.utf8.count + 1

            let (childOffset, childOffsetLength) = try decoder.decodeULEB128(at: cursor)
            cursor += childOffsetLength

            try walk(decoder, offset: Int(childOffset), name: name + edgeLabel, symbols: &symbols, visited: &visited)
        }
    }

    // MARK: - Terminal payload

    private static func makeSymbol(_ decoder: BinaryDecoder, at offset: Int, name: String) throws -> ExportedSymbol {
        let (flags, flagsLength) = try decoder.decodeULEB128(at: offset)
        var cursor = offset + flagsLength

        let isReexport = flags & UInt64(EXPORT_SYMBOL_FLAGS_REEXPORT) != 0
        let isStubAndResolver = flags & UInt64(EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER) != 0

        if isReexport {
            let (ordinal, ordinalLength) = try decoder.decodeULEB128(at: cursor)
            cursor += ordinalLength
            let importedName = try decoder.decodeString(at: cursor)

            return ExportedSymbol(
                name: name,
                flags: flags,
                reexportOrdinal: ordinal,
                reexportName: importedName.isEmpty ? nil : importedName,
            )
        }

        if isStubAndResolver {
            let (stubOffset, stubOffsetLength) = try decoder.decodeULEB128(at: cursor)
            cursor += stubOffsetLength
            let (resolverOffset, _) = try decoder.decodeULEB128(at: cursor)

            return ExportedSymbol(name: name, flags: flags, stubOffset: stubOffset, resolverOffset: resolverOffset)
        }

        let (address, _) = try decoder.decodeULEB128(at: cursor)
        return ExportedSymbol(name: name, flags: flags, address: address)
    }
}
