import Foundation

struct DyldChainedStartsInSegmentBuilder {

    let segmentInfo: [dyld_chained_starts_in_segment]

    init(_ fixupsReport: DyldChainedFixupsReport) {
        let segmentCommands = fixupsReport.file.commands.getSegmentCommands()
        var segmentInfo: [dyld_chained_starts_in_segment] = []

        for idx in 0 ..< Int(fixupsReport.startsInImage.segCount) {
            let segment = segmentCommands[idx]
            let offset = fixupsReport.startsInImage.segInfoOffset[idx]
            print("SEGMENT \(segment.segname) (offset: \(offset))")

            // NO PAGES
            if offset == 0 { continue }

            // calculate offset
            let segmentOffset = Int(fixupsReport.header.startsOffset) + Int(offset)
            let startsInSegment = fixupsReport.fixupData
                .advanced(by: segmentOffset)
                .extract(dyld_chained_starts_in_segment.self)

            print(startsInSegment)
            // getPageInfo(using: header, segmentInfo: startsInSegment)

            segmentInfo.append(startsInSegment)
        }

        self.segmentInfo = segmentInfo
    }
}

struct DyldChainedStartsInSegment {

}
