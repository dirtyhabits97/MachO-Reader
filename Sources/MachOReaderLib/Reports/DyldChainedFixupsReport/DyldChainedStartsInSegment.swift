import Foundation

struct DyldChainedStartsInSegmentBuilder {

    let segmentInfo: [DyldChainedStartsInSegment]

    init(_ fixupsReport: DyldChainedFixupsReport) {
        let segmentCommands = fixupsReport.file.commands.getSegmentCommands()
        var segmentInfo: [DyldChainedStartsInSegment] = []

        for idx in 0 ..< Int(fixupsReport.startsInImage.segCount) {
            let segment = segmentCommands[idx]
            let offset = fixupsReport.startsInImage.segInfoOffset[idx]
            print("SEGMENT \(segment.segname) (offset: \(offset))")

            // NO PAGES
            if offset == 0 { continue }

            // calculate offset
            let segmentOffset = Int(fixupsReport.header.startsOffset) + Int(offset)
            let rawValue = fixupsReport.fixupData
                .advanced(by: segmentOffset)
                .extract(dyld_chained_starts_in_segment.self)

            let startsInSegment = DyldChainedStartsInSegment(rawValue, segmentName: segment.segname)

            // TODO: implement this somehow
            // getPageInfo(using: header, segmentInfo: startsInSegment)

            segmentInfo.append(startsInSegment)
        }

        self.segmentInfo = segmentInfo
    }
}

public struct DyldChainedStartsInSegment {

    public let size: UInt32
    public let pageSize: UInt16
    // TODO: Move this to a RawRepresentable struct
    public let pointerFormat: UInt16
    public let segmentOffset: UInt64
    public let maxValidPointer: UInt32
    public let pageCount: UInt16
    public let pageStart: [UInt16]

    public let segmentName: String

    init(
        _ rawValue: dyld_chained_starts_in_segment,
        segmentName: String
    ) {
        print("hi")
        size = rawValue.size
        pageSize = rawValue.pageSize
        pointerFormat = rawValue.pointerFormat
        segmentOffset = rawValue.segmentOffset
        maxValidPointer = rawValue.maxValidPointer
        pageCount = rawValue.pageCount
        pageStart = rawValue.pageStart

        self.segmentName = segmentName
    }
}
