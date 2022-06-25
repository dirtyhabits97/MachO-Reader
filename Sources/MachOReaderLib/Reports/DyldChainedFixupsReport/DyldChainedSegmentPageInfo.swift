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

                var chainedOffset = UInt32(startsInSegment.segmentOffset)
                    + UInt32(startsInSegment.pageSize * 0)
                    + UInt32(startsInSegment.pageStart[idx])

                var done = false
                while !done {

                    // TODO: replace this with constants
                    // [DYLD_CHAINED_PTR_64, DYLD_CHAINED_PTR_64_OFFSET]
                    if [2, 6].contains(startsInSegment.pointerFormat) {

                        let data = fixupsReport.file.base.advanced(by: Int(chainedOffset))
                        let bind = data.extract(dyld_chained_ptr_64_bind.self)

                        if bind.bind {
                            // TODO: this is duplicated work as getImports
                            let chainedImport = fixupsReport.imports[Int(bind.ordinal)]
                            let symbolName = chainedImport.symbolName ?? "no symbol"
                            print("BIND   ", bind, symbolName)
                        } else {
                            let rebase = data.extract(dyld_chained_ptr_64_rebase.self)
                            print("REBASE   ", rebase)
                        }

                        if bind.next == 0 {
                            done = true
                        } else {
                            chainedOffset += UInt32(bind.next) * 4
                        }
                        // DYLD_CHAINED_PTR_32
                    } else if startsInSegment.pointerFormat == 3 {

                        let data = fixupsReport.file.base.advanced(by: Int(chainedOffset))
                        let bind = data.extract(dyld_chained_ptr_32_bind.self)
                        if bind.bind {
                            print("BIND   ", bind)
                        } else {
                            let rebase = data.extract(dyld_chained_ptr_32_rebase.self)
                            print("REBASE   ", rebase)
                        }

                        if bind.next == 0 {
                            done = true
                        } else {
                            chainedOffset += bind.next * 4
                        }
                    } else {
                        print("Unsupported format", startsInSegment.pointerFormat)
                        done = true
                        break
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
    }
}
