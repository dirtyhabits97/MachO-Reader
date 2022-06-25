import Foundation

struct DyldChainedSegmentPageInfoBuilder {

    typealias Pages = DyldChainedSegmentInfo.Pages
    typealias PageInfo = DyldChainedSegmentInfo.PageInfo

    var pageInfo: [Pages] = []

    init(_ fixupsReport: DyldChainedFixupsReport) {
        var result: [Pages] = []

        for segmentInfo in fixupsReport.segmentInfo {
            // if no pages, just add nil
            guard let startsInSegment = segmentInfo.startsInSegment else {
                result.append(Pages(pages: []))
                continue
            }

            var pages: [PageInfo] = []
            for idx in 0 ..< Int(startsInSegment.pageCount) {
                let page = PageInfo(idx: idx, offset: startsInSegment.pageStart[idx])
                pages.append(page)
            }
            result.append(Pages(pages: pages))
        }

        pageInfo = result
    }
}

public extension DyldChainedSegmentInfo {

    struct Pages {

        public let pages: [PageInfo]
    }

    struct PageInfo {

        public let idx: Int
        public let offset: UInt16
    }
}
