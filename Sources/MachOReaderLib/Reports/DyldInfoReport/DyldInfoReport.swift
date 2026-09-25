import Foundation
import MachO

/// Decodes the classic `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` rebase and bind opcode
/// streams — the pre-chained-fixups format most binaries on disk still use.
public final class DyldInfoReport {

    // MARK: - Properties

    let file: MachOFile

    public let dyldInfo: DyldInfoCommand

    public private(set) var rebases: [RebaseEntry] = []
    public private(set) var binds: [BindEntry] = []
    public private(set) var weakBinds: [BindEntry] = []
    public private(set) var lazyBinds: [BindEntry] = []

    // MARK: - Lifecycle

    init(file: MachOFile) throws {
        guard let dyldInfo = try file.commands.getDyldInfoCommand() else {
            throw MachOFileError.missingDyldInfo
        }
        self.file = file
        self.dyldInfo = dyldInfo

        let segments = try file.commands.getSegmentCommands()
        let dylibCommands = try file.commands.getDylibCommands()

        rebases = try Self.parseStream(file: file, offset: dyldInfo.rebase_off, size: dyldInfo.rebase_size) {
            var parser = RebaseOpcodeStreamParser(segments: segments)
            return try parser.parse($0)
        }
        binds = try Self.parseStream(file: file, offset: dyldInfo.bind_off, size: dyldInfo.bind_size) {
            var parser = BindOpcodeStreamParser(segments: segments, dylibCommands: dylibCommands, kind: .bind)
            return try parser.parse($0)
        }
        weakBinds = try Self.parseStream(file: file, offset: dyldInfo.weak_bind_off, size: dyldInfo.weak_bind_size) {
            var parser = BindOpcodeStreamParser(segments: segments, dylibCommands: dylibCommands, kind: .weak)
            return try parser.parse($0)
        }
        lazyBinds = try Self.parseStream(file: file, offset: dyldInfo.lazy_bind_off, size: dyldInfo.lazy_bind_size) {
            var parser = BindOpcodeStreamParser(segments: segments, dylibCommands: dylibCommands, kind: .lazy)
            return try parser.parse($0)
        }
    }

    /// Builds a bounds-checked decoder scoped to exactly the `size` bytes at
    /// `offset` within `file.base` (offsets in `dyld_info_command` are relative
    /// to it, same as `symoff`/`stroff` and chained-fixups' `dataoff`), then
    /// runs `parser` over it. Streams with `size == 0` are skipped entirely.
    private static func parseStream<T>(
        file: MachOFile,
        offset: UInt32,
        size: UInt32,
        using parser: (BinaryDecoder) throws -> [T],
    ) throws -> [T] {
        guard size > 0 else { return [] }
        let decoder = try BinaryDecoder(data: file.base).subdecoder(at: Int(offset), length: Int(size))
        return try parser(decoder)
    }
}

// MARK: - Shared helpers

/// The size of a pointer fixup slot. This library only targets 64-bit Mach-O,
/// so the stride is always 8 (matching the `nlist_64`-only symbol table path).
let dyldInfoPointerSize = 8

/// Finds the section (if any) of `segment` that contains `address`.
func dyldInfoSection(in segment: SegmentCommand, containing address: UInt64) -> String? {
    segment.sections.first { section in
        address >= section.addr && address < section.addr + section.size
    }?.sectname
}

/// Resolves a segment index against `segments`, throwing rather than crashing
/// when the opcode stream references an out-of-range index.
func dyldInfoSegment(_ segments: [SegmentCommand], at index: Int) throws -> SegmentCommand {
    guard index >= 0, index < segments.count else {
        throw BinaryDecodingError.offsetOutOfBounds(offset: index, size: segments.count)
    }
    return segments[index]
}

// MARK: - RebaseOpcodeStreamParser

/// Walks a `REBASE_OPCODE_*` stream, emitting one `RebaseEntry` per rebased slot.
struct RebaseOpcodeStreamParser {

    let segments: [SegmentCommand]

    private var entries: [RebaseEntry] = []
    // REBASE_TYPE_POINTER is the de-facto default; streams that need another
    // type emit REBASE_OPCODE_SET_TYPE_IMM explicitly before any DO_REBASE*.
    private var type = RebaseEntry.RebaseType(UInt8(REBASE_TYPE_POINTER))
    private var segmentIndex = 0
    private var segmentOffset: UInt64 = 0

    init(segments: [SegmentCommand]) {
        self.segments = segments
    }

    /// - Parameter decoder: A decoder scoped to exactly the rebase opcode stream
    ///   (e.g. via `BinaryDecoder.subdecoder(at:length:)`, or built directly from
    ///   a hand-crafted byte array in tests).
    mutating func parse(_ decoder: BinaryDecoder) throws -> [RebaseEntry] {
        var decoder = decoder

        while decoder.bytesRemaining > 0 {
            let byte = try decoder.decode(UInt8.self)
            let opcode = Int32(byte & 0xF0)
            let imm = UInt64(byte & 0x0F)

            if try applyState(opcode, imm: imm, decoder: &decoder) {
                continue
            }
            if try applyEmit(opcode, imm: imm, byte: byte, decoder: &decoder) {
                return entries
            }
        }

        return entries
    }

    private mutating func emit() throws {
        let segment = try dyldInfoSegment(segments, at: segmentIndex)
        let address = segment.vmaddr + segmentOffset
        entries.append(RebaseEntry(
            segmentIndex: segmentIndex,
            segmentName: segment.segname,
            sectionName: dyldInfoSection(in: segment, containing: address),
            address: address,
            type: type,
        ))
    }

    private mutating func emitRepeatedly(_ times: UInt64, extra: UInt64 = 0) throws {
        for _ in 0 ..< times {
            try emit()
            segmentOffset += UInt64(dyldInfoPointerSize) + extra
        }
    }

    /// Opcodes that only update parser state. Returns `true` if handled.
    private mutating func applyState(_ opcode: Int32, imm: UInt64, decoder: inout BinaryDecoder) throws -> Bool {
        switch opcode {
        case REBASE_OPCODE_SET_TYPE_IMM:
            type = RebaseEntry.RebaseType(UInt8(imm))
        case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
            segmentIndex = Int(imm)
            segmentOffset = try decoder.decodeULEB128()
        case REBASE_OPCODE_ADD_ADDR_ULEB:
            segmentOffset += try decoder.decodeULEB128()
        case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
            segmentOffset += imm * UInt64(dyldInfoPointerSize)
        default:
            return false
        }
        return true
    }

    /// Opcodes that emit one or more entries, plus DONE. Returns `true` when
    /// the stream is finished.
    private mutating func applyEmit(
        _ opcode: Int32,
        imm: UInt64,
        byte: UInt8,
        decoder: inout BinaryDecoder,
    ) throws -> Bool {
        switch opcode {
        case REBASE_OPCODE_DONE:
            return true
        case REBASE_OPCODE_DO_REBASE_IMM_TIMES:
            try emitRepeatedly(imm)
        case REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
            try emitRepeatedly(decoder.decodeULEB128())
        case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
            try emitRepeatedly(1, extra: decoder.decodeULEB128())
        case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
            let count = try decoder.decodeULEB128()
            let skip = try decoder.decodeULEB128()
            try emitRepeatedly(count, extra: skip)
        default:
            throw BinaryDecodingError.invalidString(reason: "Unknown rebase opcode 0x\(String(byte, radix: 16))")
        }
        return false
    }
}

// MARK: - BindOpcodeStreamParser

/// Walks a `BIND_OPCODE_*` stream (bind, weak-bind or lazy-bind), emitting one
/// `BindEntry` per bound slot.
struct BindOpcodeStreamParser {

    let segments: [SegmentCommand]
    let dylibCommands: [DylibCommand]
    let kind: BindEntry.Kind

    private var entries: [BindEntry] = []
    private var dylibOrdinal = 0
    private var symbolName = ""
    private var isWeakImport = false
    // BIND_TYPE_POINTER is the de-facto default — the lazy-bind stream in
    // particular never emits BIND_OPCODE_SET_TYPE_IMM.
    private var type = BindEntry.BindType(UInt8(BIND_TYPE_POINTER))
    private var addend: Int64 = 0
    private var segmentIndex = 0
    private var segmentOffset: UInt64 = 0

    init(segments: [SegmentCommand], dylibCommands: [DylibCommand], kind: BindEntry.Kind) {
        self.segments = segments
        self.dylibCommands = dylibCommands
        self.kind = kind
    }

    /// - Parameter decoder: A decoder scoped to exactly the bind opcode stream
    ///   (e.g. via `BinaryDecoder.subdecoder(at:length:)`, or built directly from
    ///   a hand-crafted byte array in tests).
    mutating func parse(_ decoder: BinaryDecoder) throws -> [BindEntry] {
        var decoder = decoder

        while decoder.bytesRemaining > 0 {
            let byte = try decoder.decode(UInt8.self)
            let opcode = Int32(byte & 0xF0)
            let imm = UInt64(byte & 0x0F)

            if try applyState(opcode, imm: imm, decoder: &decoder) {
                continue
            }
            if try applyEmit(opcode, imm: imm, byte: byte, decoder: &decoder) {
                return entries
            }
        }

        return entries
    }

    private mutating func emit() throws {
        let segment = try dyldInfoSegment(segments, at: segmentIndex)
        let address = segment.vmaddr + segmentOffset
        entries.append(BindEntry(
            kind: kind,
            segmentIndex: segmentIndex,
            segmentName: segment.segname,
            sectionName: dyldInfoSection(in: segment, containing: address),
            address: address,
            type: type,
            dylibOrdinal: dylibOrdinal,
            dylibName: dylibName(for: dylibOrdinal),
            symbolName: symbolName,
            addend: addend,
            isWeakImport: isWeakImport,
        ))
    }

    private mutating func emitRepeatedly(_ times: UInt64, extra: UInt64 = 0) throws {
        for _ in 0 ..< times {
            try emit()
            segmentOffset += UInt64(dyldInfoPointerSize) + extra
        }
    }

    /// Opcodes that only update parser state. Returns `true` if handled.
    private mutating func applyState(_ opcode: Int32, imm: UInt64, decoder: inout BinaryDecoder) throws -> Bool {
        switch opcode {
        case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
            dylibOrdinal = Int(imm)
        case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
            dylibOrdinal = try Int(decoder.decodeULEB128())
        case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
            // A non-zero 4-bit immediate is sign-extended to a small negative
            // ordinal (BIND_SPECIAL_DYLIB_SELF / _MAIN_EXECUTABLE / _FLAT_LOOKUP).
            dylibOrdinal = imm == 0 ? 0 : Int(Int8(bitPattern: UInt8(imm) | 0xF0))
        case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
            isWeakImport = imm & UInt64(BIND_SYMBOL_FLAGS_WEAK_IMPORT) != 0
            symbolName = try decoder.decodeString()
        case BIND_OPCODE_SET_TYPE_IMM:
            type = BindEntry.BindType(UInt8(imm))
        case BIND_OPCODE_SET_ADDEND_SLEB:
            addend = try decoder.decodeSLEB128()
        case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
            segmentIndex = Int(imm)
            segmentOffset = try decoder.decodeULEB128()
        case BIND_OPCODE_ADD_ADDR_ULEB:
            segmentOffset += try decoder.decodeULEB128()
        default:
            return false
        }
        return true
    }

    /// Opcodes that emit one or more entries, plus DONE/THREADED. Returns
    /// `true` when the stream is finished.
    private mutating func applyEmit(
        _ opcode: Int32,
        imm: UInt64,
        byte: UInt8,
        decoder: inout BinaryDecoder,
    ) throws -> Bool {
        switch opcode {
        case BIND_OPCODE_DONE:
            // In the lazy-bind stream DONE only separates entries; in the
            // bind / weak-bind streams it ends the whole stream.
            return kind != .lazy
        case BIND_OPCODE_DO_BIND:
            try emitRepeatedly(1)
        case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
            try emitRepeatedly(1, extra: decoder.decodeULEB128())
        case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
            try emitRepeatedly(1, extra: imm * UInt64(dyldInfoPointerSize))
        case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
            let count = try decoder.decodeULEB128()
            let skip = try decoder.decodeULEB128()
            try emitRepeatedly(count, extra: skip)
        case BIND_OPCODE_THREADED:
            // Only used by old arm64e binaries binding via LC_DYLD_INFO; unsupported here.
            throw BinaryDecodingError.invalidString(
                reason: "BIND_OPCODE_THREADED is not supported (arm64e threaded binding via LC_DYLD_INFO)",
            )
        default:
            throw BinaryDecodingError.invalidString(reason: "Unknown bind opcode 0x\(String(byte, radix: 16))")
        }
        return false
    }

    private func dylibName(for ordinal: Int) -> String? {
        guard ordinal >= 1, ordinal <= dylibCommands.count else { return nil }
        return dylibCommands[ordinal - 1].dylib.name.split(separator: "/").last.map(String.init)
    }
}
