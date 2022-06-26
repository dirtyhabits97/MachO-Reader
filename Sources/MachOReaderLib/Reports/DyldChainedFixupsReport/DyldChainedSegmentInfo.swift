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

    public struct StartsInSegment {

        public let size: UInt32
        public let pageSize: UInt16
        public let pointerFormat: PointerFormat
        public let segmentOffset: UInt64
        public let maxValidPointer: UInt32
        public let pageCount: UInt16
        public let pageStart: [UInt16]

        init(_ rawValue: dyld_chained_starts_in_segment) {
            size = rawValue.size
            pageSize = rawValue.pageSize
            pointerFormat = PointerFormat(rawValue.pointerFormat)
            segmentOffset = rawValue.segmentOffset
            maxValidPointer = rawValue.maxValidPointer
            pageCount = rawValue.pageCount
            pageStart = rawValue.pageStart
        }
    }

    public let segmentName: String
    public let segInfoOffset: UInt32

    public fileprivate(set) var startsInSegment: StartsInSegment?

    // segInfoOffset == 0 means NO PAGES
    var hasPages: Bool { segInfoOffset != 0 }

    init(segmentName: String, segInfoOffset: UInt32) {
        self.segmentName = segmentName
        self.segInfoOffset = segInfoOffset
    }
}

public extension DyldChainedSegmentInfo {

    struct PointerFormat: RawRepresentable, Equatable, Readable {

        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: UInt16) {
            self.rawValue = rawValue
        }

        // swiftlint:disable identifier_name
        /// stride 8, unauth target is vmaddr
        static let DYLD_CHAINED_PTR_ARM64E = PointerFormat(1)
        /// target is vmaddr
        static let DYLD_CHAINED_PTR_64 = PointerFormat(2)
        static let DYLD_CHAINED_PTR_32 = PointerFormat(3)
        static let DYLD_CHAINED_PTR_32_CACHE = PointerFormat(4)
        static let DYLD_CHAINED_PTR_32_FIRMWARE = PointerFormat(5)
        /// target is vm offset
        static let DYLD_CHAINED_PTR_64_OFFSET = PointerFormat(6)
        // old name, replaced by DYLD_CHAINED_PTR_ARM64E_KERNEL
        // static let DYLD_CHAINED_PTR_ARM64E_OFFSET = PointerFormat(7)
        /// stride 4, unauth target is vm offset
        static let DYLD_CHAINED_PTR_ARM64E_KERNEL = PointerFormat(7)
        static let DYLD_CHAINED_PTR_64_KERNEL_CACHE = PointerFormat(8)
        /// stride 8, unauth target is vm offset
        static let DYLD_CHAINED_PTR_ARM64E_USERLAND = PointerFormat(9)
        /// stride 4, unauth target is vmaddr
        static let DYLD_CHAINED_PTR_ARM64E_FIRMWARE = PointerFormat(10)
        /// stride 1, x86_64 kernel caches
        static let DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE = PointerFormat(11)
        /// stride 8, unauth target is vm offset, 24-bit bind
        static let DYLD_CHAINED_PTR_ARM64E_USERLAND24 = PointerFormat(12)
        // swiftlint:enable identifier_name

        public var readableValue: String? {
            switch self {
            case .DYLD_CHAINED_PTR_ARM64E: return "DYLD_CHAINED_PTR_ARM64E"
            case .DYLD_CHAINED_PTR_64: return "DYLD_CHAINED_PTR_64"
            case .DYLD_CHAINED_PTR_32: return "DYLD_CHAINED_PTR_32"
            case .DYLD_CHAINED_PTR_32_CACHE: return "DYLD_CHAINED_PTR_32_CACHE"
            case .DYLD_CHAINED_PTR_32_FIRMWARE: return "DYLD_CHAINED_PTR_32_FIRMWARE"
            case .DYLD_CHAINED_PTR_64_OFFSET: return "DYLD_CHAINED_PTR_64_OFFSET"
            case .DYLD_CHAINED_PTR_ARM64E_KERNEL: return "DYLD_CHAINED_PTR_ARM64E_KERNEL"
            case .DYLD_CHAINED_PTR_64_KERNEL_CACHE: return "DYLD_CHAINED_PTR_64_KERNEL_CACHE"
            case .DYLD_CHAINED_PTR_ARM64E_USERLAND: return "DYLD_CHAINED_PTR_ARM64E_USERLAND"
            case .DYLD_CHAINED_PTR_ARM64E_FIRMWARE: return "DYLD_CHAINED_PTR_ARM64E_FIRMWARE"
            case .DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE: return "DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE"
            case .DYLD_CHAINED_PTR_ARM64E_USERLAND24: return "DYLD_CHAINED_PTR_ARM64E_USERLAND24"
            default: return nil
            }
        }
    }
}
