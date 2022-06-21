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

    // MARK: - Methods


    // TODO: delete this
    public func test() {

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
    }
}
