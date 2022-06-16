import Foundation
import MachO

public struct MachOFile {

    // MARK: - Properties

    public let fatHeader: FatHeader?
    public let header: MachOHeader
    public private(set) var commands: [LoadCommand]

    /// A pointer to the start of the this file in memory.
    private var base: Data

    // MARK: - Lifecycle

    public init(from url: URL, arch: String?) throws {
        self.init(from: try Data(contentsOf: url), arch: arch)
    }

    init(from data: Data, arch: String?) {
        fatHeader = FatHeader(from: data)

        var data = data
        if let offset = fatHeader?.offset(for: CPUType(from: arch)) {
            data = data.advanced(by: Int(offset))
        }

        // TODO: delete this
        base = data

        header = MachOHeader(from: data)

        var commands = [LoadCommand]()
        var offset = header.size

        for _ in 0 ..< header.ncmds {
            let data = data.advanced(by: offset)
            let loadCommand = LoadCommand(from: data, isSwapped: header.magic.isSwapped)
            commands.append(loadCommand)
            offset += Int(loadCommand.cmdsize)
        }

        self.commands = commands
    }

    // MARK: - Methods

    func getLinkedItSegment() -> SegmentCommand? {
        commands
            .lazy
            .compactMap { loadCommand -> SegmentCommand? in
                guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
                return segmentCommand
            }
            .filter { segmentCommand in segmentCommand.segname == "__LINKEDIT" }
            .first
    }

    func getDyldChainedFixups() -> LinkedItDataCommand? {
        commands
            .lazy
            .filter { loadCommand in loadCommand.cmd == .dyldChainedFixups }
            .compactMap { loadCommand -> LinkedItDataCommand? in
                guard case let .linkedItDataCommand(linkedItDataCommand) = loadCommand.commandType() else { return nil }
                return linkedItDataCommand
            }
            .first
    }

    func getDylibCommands() -> [DylibCommand] {
        commands.compactMap { loadCommand -> DylibCommand? in
            guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
            return dylibCommand
        }
    }

    func getSegmentCommands() -> [SegmentCommand] {
        commands.compactMap { loadCommand -> SegmentCommand? in
            guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
            return segmentCommand
        }
    }

    // TODO: delete this
    public func test() {
        guard let linkedItSegment = getLinkedItSegment() else {
            assertionFailure("Expected a LinkedIt segment in the macho file.")
            return
        }

        guard let dyldChainedFixups = getDyldChainedFixups() else {
            assertionFailure("Expected a DyldChainedFixups command in the macho file.")
            return
        }

        let dyldOffset = dyldChainedFixups.dataoff

        // var offset = Int(dyldOffset)

        let baseData = base.advanced(by: Int(dyldOffset))

        let dyldChainedFixupsHeader = baseData.extract(dyld_chained_fixups_header.self)
        print(dyldChainedFixupsHeader)
        // offset += MemoryLayout.size(ofValue: dyldChainedFixupsHeader.startsOffset)

        let dyldChainedStartsInImage = baseData
            .advanced(by: Int(dyldChainedFixupsHeader.startsOffset))
            .extract(dyld_chained_starts_in_image.self)
        print(dyldChainedStartsInImage)

        do {
            var offset = Int(dyldChainedFixupsHeader.startsOffset)
            let segCount = baseData
                .advanced(by: offset)
                .extract(UInt32.self)
            offset += MemoryLayout.size(ofValue: segCount)
            print("=== in block ===")
            var pointers: [UInt32] = []
            for _ in 0 ..< segCount {
                let pointer = baseData
                    .advanced(by: offset)
                    .extract(UInt32.self)
                pointers.append(pointer)
                offset += MemoryLayout.size(ofValue: pointer)
            }
            print(segCount, pointers)
            print("=== in block ===")

            let segmentCommands = getSegmentCommands()
            for idx in 0 ..< Int(segCount) {
                let segment = segmentCommands[idx]
                let offset = MemoryLayout<UInt32>.size * idx
                let pointer = pointers[idx]
                print(segment.segname, pointer)

                if pointer == 0 { continue }

                let segmentOffset = 0 + Int(dyldChainedFixupsHeader.startsOffset) + Int(pointer)
                print("segmentOffset: ", segmentOffset)
                let startsInSegment = baseData.advanced(by: segmentOffset).extract(dyld_chain_starts_in_segment.self)
                print(startsInSegment)
            }
        }

        let dylibCommands = getDylibCommands()
        print(dylibCommands.count)

        print("IMPORTS...")
        var importsOffset = Int(dyldChainedFixupsHeader.importsOffset)
        var pretty: [Pretty] = []
        for idx in 0 ..< dyldChainedFixupsHeader.importsCount {
            let foo = baseData.advanced(by: importsOffset).extract(dyld_chained_import.self)
            // TODO: split the UInt32 into libOrdinal: 8, weakimport: 1; name_offset: 23.
            let mask1: UInt32 = 1 << 8 - 1
            let mask2: UInt32 = 1 << 1 - 1
            let mask3: UInt32 = 1 << 23 - 1

            let libOrdinal = foo.rawValue & mask1
            let weakImport = foo.rawValue >> 8 & mask2
            let nameOffset = foo.rawValue >> 9 & mask3

            pretty.append(.init(libOrdinal: libOrdinal, weakImport: weakImport, nameOffset: nameOffset))

            importsOffset += MemoryLayout.size(ofValue: foo)

            // TODO: get dylib name
            // TODO: get symbol name
        }

        // swiftlint:disable identifier_name
        for (idx, p) in pretty.enumerated() {
            // TODO: handle lib ordinal constants 254 and 255
            let name = dylibCommands[Int(p.libOrdinal) - 1].dylib.name.split(separator: "/").last!

            let offsetToSymbolName = 0 + dyldChainedFixupsHeader.symbolsOffset + p.nameOffset
            let symbolNamename = baseData.advanced(by: Int(offsetToSymbolName)).nextString()!

            // let str = String(bytes: chars, encoding: String.Encoding.utf8)
            // print(str)

            // let str = String(withUnsafePointer(to: baseData.advanced(by: Int(offsetToSymbolName))) {
            //     $0.withMemoryRebound(to: [CChar].self, capacity: strLen) {
            //         String(cString: $0)
            //     }
            // })

            // print(strLen)

            // // swiftlint:disable:next line_length
            // let raw = baseData.advanced(by: Int(offsetToSymbolName)).extract((CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar).self)
            // print("offset: \(offsetToSymbolName)", String.init(char16: raw))

            // print("[\(idx)] lib_ordinal: \(libOrdinal) (\(name))   weak_import: \(weakImport)   name_offset: \(nameOffset)")
            print(p, name, symbolNamename)
        }
    }
}

struct Pretty {
    let libOrdinal: UInt32
    let weakImport: UInt32
    let nameOffset: UInt32
}

// swiftlint:disable:next type_name
struct dyld_chain_starts_in_segment {
    let size: UInt32
    let pageSize: UInt16
    let pointerFormat: UInt16
    let segmentOffset: UInt64
    let maxValidPointer: UInt32
    let pageCount: UInt16
    let pageStart: UInt16
}

// TODO: this should come from /Applications/Xcode.13.3.0.13E113.app.../mach-o/fixup-chains.h
// for some reason it doesn't let me import it.
// struct dyld_chained_fixups_header
// {
//     uint32_t    fixups_version;    // 0
//     uint32_t    starts_offset;     // offset of dyld_chained_starts_in_image in chain_data
//     uint32_t    imports_offset;    // offset of imports table in chain_data
//     uint32_t    symbols_offset;    // offset of symbol strings in chain_data
//     uint32_t    imports_count;     // number of imported symbol names
//     uint32_t    imports_format;    // DYLD_CHAINED_IMPORT*
//     uint32_t    symbols_format;    // 0 => uncompressed, 1 => zlib compressed
// };
// swiftlint:disable:next type_name
struct dyld_chained_fixups_header {
    let fixupsVersion: UInt32
    let startsOffset: UInt32
    let importsOffset: UInt32
    let symbolsOffset: UInt32
    let importsCount: UInt32
    let importsFormat: UInt32
    let symbolsFormat: UInt32
}

// This struct is embedded in LC_DYLD_CHAINED_FIXUPS payload
// struct dyld_chained_starts_in_image
// {
//     uint32_t    seg_count;
//     uint32_t    seg_info_offset[1];  // each entry is offset into this struct for that segment
//     // followed by pool of dyld_chain_starts_in_segment data
// };
// swiftlint:disable:next type_name
struct dyld_chained_starts_in_image {
    let segCount: UInt32
    // let segInfoOffset: UnsafePointer<UInt32>
    let segInfoOffset: UInt32
}

// DYLD_CHAINED_IMPORT
// struct dyld_chained_import
// {
//     uint32_t    lib_ordinal :  8,
//                 weak_import :  1,
//                 name_offset : 23;
// };
// swiftlint:disable:next type_name
struct dyld_chained_import {
    let rawValue: UInt32
}
