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

                // Each fixup advances chainedOffset by `next * stride` bytes; the stride
                // depends on the pointer format (e.g. arm64e uses 8, generic 64-bit uses 4).
                // A page holds at most pageSize / stride fixups, which also bounds the walk
                // against a malformed `next` that would otherwise loop forever.
                let stride = startsInSegment.pointerFormat.stride
                let maxFixupsPerPage = stride > 0 ? Int(startsInSegment.pageSize) / Int(stride) : 0

                var done = false
                while !done {
                    let data = fixupsReport.file.base.advanced(by: Int(chainedOffset))

                    guard let bindOrRebase = DyldChainedPtrBindOrRebase(
                        from: data,
                        pointerFormat: startsInSegment.pointerFormat,
                    ) else {
                        print("Unsupported format", startsInSegment.pointerFormat)
                        done = true
                        break
                    }

                    page.bindOrRebase.append(bindOrRebase)

                    if bindOrRebase.next == 0 || page.bindOrRebase.count >= maxFixupsPerPage {
                        done = true
                    } else {
                        chainedOffset += UInt32(bindOrRebase.next) * stride
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
