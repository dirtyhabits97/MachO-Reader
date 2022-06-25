import Foundation

struct DyldChainedStartsInSegmentBuilder {

    let segmentInfo: [DyldChainedSegmentInfo]

    init(_ fixupsReport: DyldChainedFixupsReport) {
        let segmentCommands = fixupsReport.file.commands.getSegmentCommands()
        var result: [DyldChainedSegmentInfo] = []

        for idx in 0 ..< Int(fixupsReport.startsInImage.segCount) {
            let segment = segmentCommands[idx]
            let offset = fixupsReport.startsInImage.segInfoOffset[idx]

            var segmentInfo = DyldChainedSegmentInfo(segmentName: segment.segname, segInfoOffset: offset)

            if segmentInfo.hasPages {
                // calculate offset
                let segmentOffset = Int(fixupsReport.header.startsOffset) + Int(offset)
                segmentInfo.startsInSegment = .init(
                    fixupsReport.fixupData
                        .advanced(by: segmentOffset)
                        .extract(dyld_chained_starts_in_segment.self)
                )

                // TODO: implement this somehow
                // getPageInfo(using: header, segmentInfo: startsInSegment)
            }

            result.append(segmentInfo)
        }

        segmentInfo = result
    }
}

// TODO: document this
public struct DyldChainedSegmentInfo {

    public struct DyldChainedStartsInSegment {

        public let size: UInt32
        public let pageSize: UInt16
        // TODO: Move this to a RawRepresentable struct
        public let pointerFormat: UInt16
        public let segmentOffset: UInt64
        public let maxValidPointer: UInt32
        public let pageCount: UInt16
        public let pageStart: [UInt16]

        init(_ rawValue: dyld_chained_starts_in_segment) {
            size = rawValue.size
            pageSize = rawValue.pageSize
            pointerFormat = rawValue.pointerFormat
            segmentOffset = rawValue.segmentOffset
            maxValidPointer = rawValue.maxValidPointer
            pageCount = rawValue.pageCount
            pageStart = rawValue.pageStart
        }
    }

    public let segmentName: String
    public let segInfoOffset: UInt32

    public fileprivate(set) var startsInSegment: DyldChainedStartsInSegment?

    // segInfoOffset == 0 means NO PAGES
    var hasPages: Bool { segInfoOffset != 0 }

    init(segmentName: String, segInfoOffset: UInt32) {
        self.segmentName = segmentName
        self.segInfoOffset = segInfoOffset
    }
}
