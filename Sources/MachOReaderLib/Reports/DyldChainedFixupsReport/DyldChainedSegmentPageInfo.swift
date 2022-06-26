import Foundation

struct DyldChainedSegmentPageInfoBuilder {

    typealias Pages = DyldChainedSegmentInfo.Pages
    typealias PageInfo = DyldChainedSegmentInfo.PageInfo

    var pageInfo: [Pages] = []

    init(_ fixupsReport: DyldChainedFixupsReport) {
        var result: [Pages] = []

        for segmentInfo in fixupsReport.segmentInfo {
            // if no pages, just add nil
            guard segmentInfo.hasPages, let startsInSegment = segmentInfo.startsInSegment else {
                result.append(Pages(pages: []))
                continue
            }

            var pages: [PageInfo] = []
            for idx in 0 ..< Int(startsInSegment.pageCount) {
                var page = PageInfo(idx: idx, offset: startsInSegment.pageStart[idx])

                var chainedOffset = UInt32(startsInSegment.segmentOffset)
                    + UInt32(startsInSegment.pageSize * 0)
                    + UInt32(startsInSegment.pageStart[idx])

                var done = false
                while !done {
                    let data = fixupsReport.file.base.advanced(by: Int(chainedOffset))

                    guard let bindOrRebase = DyldChainedPtrBindOrRebase(
                        from: data,
                        pointerFormat: startsInSegment.pointerFormat
                    ) else {
                        print("Unsupported format", startsInSegment.pointerFormat)
                        done = true
                        break
                    }

                    page.bindOrRebase.append(bindOrRebase)

                    if bindOrRebase.next == 0 {
                        done = true
                    } else {
                        chainedOffset += UInt32(bindOrRebase.next) * 4
                    }
                }

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
        public fileprivate(set) var bindOrRebase: [DyldChainedPtrBindOrRebase] = []
    }
}
