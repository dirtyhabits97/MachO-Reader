import Foundation

// This struct is embedded in LC_DYLD_CHAINED_FIXUPS payload
// struct dyld_chained_starts_in_image
// {
//     uint32_t    seg_count;
//     uint32_t    seg_info_offset[1];  // each entry is offset into this struct for that segment
//     // followed by pool of dyld_chain_starts_in_segment data
// };
// swiftlint:disable:next type_name
struct dyld_chained_starts_in_image: CustomExtractable {
    let segCount: UInt32
    let segInfoOffset: [UInt32]

    init(from data: Data) {
        segCount = data.extract(UInt32.self)
        segInfoOffset = data
            .advanced(by: MemoryLayout.size(ofValue: segCount))
            .extractArray(UInt32.self, count: Int(segCount))
    }
}

// struct dyld_chained_ptr_64_bind
// {
//     uint64_t    ordinal   : 24,
//                 addend    :  8,   // 0 thru 255
//                 reserved  : 19,   // all zeros
//                 next      : 12,   // 4-byte stride
//                 bind      :  1;   // == 1
// };
// swiftlint:disable:next type_name
struct dyld_chained_ptr_64_bind: CustomExtractable {

    let ordinal: UInt64
    let addend: UInt64
    let reserved: UInt64
    let next: UInt64
    let bind: Bool

    init(from rawValue: UInt64) {
        let values = rawValue.split(using: [24, 8, 19, 12, 1])
        ordinal = values[0]
        addend = values[1]
        reserved = values[2]
        next = values[3]
        bind = values[4] == 1
    }

    init(from data: Data) {
        self.init(from: data.extract(UInt64.self))
    }
}

// This struct is embedded in dyld_chain_starts_in_image
// and passed down to the kernel for page-in linking
// struct dyld_chained_starts_in_segment
// {
//     uint32_t    size;               size of this (amount kernel needs to copy)
//     uint16_t    page_size;          0x1000 or 0x4000
//     uint16_t    pointer_format;     DYLD_CHAINED_PTR_*
//     uint64_t    segment_offset;     offset in memory to start of segment
//     uint32_t    max_valid_pointer;  for 32-bit OS, any value beyond this is not a pointer
//     uint16_t    page_count;         how many pages are in array
//     uint16_t    page_start[1];      each entry is offset in each page of first element in chain
//                                     or DYLD_CHAINED_PTR_START_NONE if no fixups on page
//  uint16_t    chain_starts[1];    // some 32-bit formats may require multiple starts per page.
//                                     for those, if high bit is set in page_starts[], then it
//                                     is index into chain_starts[] which is a list of starts
//                                     the last of which has the high bit set
// };
@dynamicMemberLookup
// swiftlint:disable:next type_name
struct dyld_chained_starts_in_segment: CustomExtractable {

    struct UnderlyingValue {
        let size: UInt32
        let pageSize: UInt16
        let pointerFormat: UInt16
        let segmentOffset: UInt64
        let maxValidPointer: UInt32
        let pageCount: UInt16
    }

    private let underlyingValue: UnderlyingValue
    // TODO: figure out a better way to handle array pointers in swift
    let pageStart: [UInt16]

    init(from data: Data) {
        underlyingValue = data.extract(UnderlyingValue.self)
        pageStart = data
            .advanced(by: MemoryLayout.size(ofValue: underlyingValue))
            .extractArray(UInt16.self, count: Int(underlyingValue.pageCount))
    }

    subscript<T>(dynamicMember keyPath: KeyPath<UnderlyingValue, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}
