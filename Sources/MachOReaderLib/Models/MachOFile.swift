import Foundation
import MachO

public struct MachOFile {

    // MARK: - Properties

    public let fatHeader: FatHeader?
    public let header: MachOHeader
    public private(set) var commands: [LoadCommand]

    /// A pointer to the start of the header of this file in memory.
    private(set) var base: Data

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

    // MARK: - Reports

    public func dyldChainedFixupsReport() -> DyldChainedFixupsReport.Report {
        DyldChainedFixupsReport(file: self).report()
    }


    // TODO: delete this
    public func test() {
        // let dyldOffset = dyldChainedFixups.dataoff

        // let baseData = base.advanced(by: Int(dyldOffset))

        // let dyldChainedFixupsHeader = baseData.extract(dyld_chained_fixups_header.self)
        // print(dyldChainedFixupsHeader)

        // let dyldChainedStartsInImage = baseData
        //     .advanced(by: Int(dyldChainedFixupsHeader.startsOffset))
        //     .extract(dyld_chained_starts_in_image.self)
        // print(dyldChainedStartsInImage)

        // let segCount = dyldChainedStartsInImage.segCount
        // let pointers = dyldChainedStartsInImage.segInfoOffset
        // print(segCount, pointers)

        // let segmentCommands = getSegmentCommands()
        // for idx in 0 ..< Int(segCount) {
        //     let segment = segmentCommands[idx]
        //     let pointer = pointers[idx]
        //     print(segment.segname, pointer)

        //     if pointer == 0 { continue }

        //     let segmentOffset = 0 + Int(dyldChainedFixupsHeader.startsOffset) + Int(pointer)
        //     let startsInSegment = baseData.advanced(by: segmentOffset).extract(dyld_chained_starts_in_segment.self)
        //     print(startsInSegment)

        //     for idx in 0 ..< Int(startsInSegment.pageCount) {
        //         print("PAGE: \(idx) (offset: \(startsInSegment.pageStart[idx]))")

        //         var chainedOffset: UInt32 = 0 + UInt32(startsInSegment.segmentOffset) + UInt32(startsInSegment.pageSize * 0) + UInt32(startsInSegment.pageStart[idx])
        //         print(String(format: "%08llx", startsInSegment.segmentOffset), "Chained offset: \(chainedOffset)")

        //         var done = false
        //         while !done {
        //             // TODO: replace this with constants
        //             // [DYLD_CHAINED_PTR_64, DYLD_CHAINED_PTR_64_OFFSET]
        //             if [2, 6].contains(startsInSegment.pointerFormat) {

        //                 let bind = base
        //                     .advanced(by: Int(chainedOffset))
        //                     .extract(dyld_chained_ptr_64_bind.self)

        //                 print("Bind: \(bind)")
        //                 // TODO: check if is bind or rebind

        //                 if bind.next == 0 {
        //                     done = true
        //                 } else {
        //                     chainedOffset += UInt32(bind.next) * 4
        //                 }

        //             } else {
        //                 print("Unsupported format", startsInSegment.pointerFormat)
        //                 done = true
        //                 break
        //             }
        //         }
        //     }
        // }
        // print("=== in block ===")

        // var importsOffset = Int(dyldChainedFixupsHeader.importsOffset)
        // for _ in 0 ..< dyldChainedFixupsHeader.importsCount {
        //     let chainedImport = baseData.advanced(by: importsOffset).extract(dyld_chained_import.self)

        //     let name = dylibCommands[Int(chainedImport.libOrdinal) - 1].dylib.name.split(separator: "/").last!
        //     let offsetToSymbolName = 0 + dyldChainedFixupsHeader.symbolsOffset + chainedImport.nameOffset
        //     let symbolName = baseData.advanced(by: Int(offsetToSymbolName)).extractString()!

        //     print(chainedImport, "\(name): \(symbolName)")
        //     // TODO: make it easier for CModels to propose their own size.
        //     importsOffset += MemoryLayout<UInt32>.size
        // }
    }
}
