import Foundation

// swiftlint:disable type_name identifier_name line_length

// These models should come from /Applications/Xcode.13.3.0.13E113.app.../mach-o/fixup-chains.h
// but `import MachO.fixups` doesn't work. For some reason it doesn't let me import it.

/// header of the LC_DYLD_CHAINED_FIXUPS payload
struct dyld_chained_fixups_header {
    /// 0
    let fixups_version: UInt32
    /// offset of dyld_chained_starts_in_image in chain_data
    let starts_offset: UInt32
    /// offset of imports table in chain_data
    let imports_offset: UInt32
    /// offset of symbol strings in chain_data
    let symbols_offset: UInt32
    /// number of imported symbol names
    let imports_count: UInt32
    /// DYLD_CHAINED_IMPORT*
    let imports_format: UInt32
    /// 0 => uncompressed, 1 => zlib compressed
    let symbols_format: UInt32
}

/// This struct is embedded in LC_DYLD_CHAINED_FIXUPS payload
struct dyld_chained_starts_in_image: CustomExtractable {

    let segCount: UInt32
    /// each entry is offset into this struct for that segment
    /// followed by pool of dyld_chain_starts_in_segment data
    let segInfoOffset: [UInt32]

    init(from data: Data) {
        segCount = data.extract(UInt32.self)
        segInfoOffset = data
            .advanced(by: MemoryLayout.size(ofValue: segCount))
            .extractArray(UInt32.self, count: Int(segCount))
    }
}

// DYLD_CHAINED_IMPORT
// struct dyld_chained_import
// {
//     uint32_t    lib_ordinal :  8,
//                 weak_import :  1,
//                 name_offset : 23;
// };
struct dyld_chained_import: RawRepresentable {

    let rawValue: UInt32

    init(rawValue: UInt32) {
        self.rawValue = rawValue
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

// DYLD_CHAINED_PTR_64/DYLD_CHAINED_PTR_64_OFFSET
// struct dyld_chained_ptr_64_rebase
// {
//     uint64_t    target    : 36,    // 64GB max image size (DYLD_CHAINED_PTR_64 => vmAddr, DYLD_CHAINED_PTR_64_OFFSET => runtimeOffset)
//                 high8     :  8,    // top 8 bits set to this (DYLD_CHAINED_PTR_64 => after slide added, DYLD_CHAINED_PTR_64_OFFSET => before slide added)
//                 reserved  :  7,    // all zeros
//                 next      : 12,    // 4-byte stride
//                 bind      :  1;    // == 0
// };
struct dyld_chained_ptr_64_rebase: CustomExtractable {

    let target: UInt64
    let high8: UInt8
    let reserved: UInt8
    let next: UInt16
    let bind: Bool

    init(from rawValue: UInt64) {
        let values = rawValue.split(using: [36, 8, 7, 12, 1])
        target = values[0]
        high8 = UInt8(truncatingIfNeeded: values[1])
        reserved = UInt8(truncatingIfNeeded: values[2])
        next = UInt16(truncatingIfNeeded: values[3])
        bind = values[4] == 1
    }

    init(from data: Data) {
        self.init(from: data.extract(UInt64.self))
    }
}

// MARK: - 32 bit counterparts

// DYLD_CHAINED_PTR_32
// struct dyld_chained_ptr_32_bind
// {
//     uint32_t    ordinal   : 20,
//                 addend    :  6,   // 0 thru 63
//                 next      :  5,   // 4-byte stride
//                 bind      :  1;   // == 1
// };
struct dyld_chained_ptr_32_bind: CustomExtractable {

    let ordinal: UInt32
    let addend: UInt8
    let next: UInt32
    let bind: Bool

    init(from rawValue: UInt32) {
        let values = rawValue.split(using: [20, 6, 5, 1])
        ordinal = values[0]
        addend = UInt8(truncatingIfNeeded: values[1])
        next = values[2]
        bind = values[3] == 1
    }

    init(from data: Data) {
        self.init(from: data.extract(UInt32.self))
    }
}

// struct dyld_chained_ptr_32_rebase
// {
//     uint32_t    target    : 26,   // vmaddr, 64MB max image size
//                 next      :  5,   // 4-byte stride
//                 bind      :  1;   // == 0
// };
struct dyld_chained_ptr_32_rebase: CustomExtractable {

    let target: UInt32
    let next: UInt32
    let bind: Bool

    init(from rawValue: UInt32) {
        let values = rawValue.split(using: [26, 5, 1])
        target = values[0]
        next = values[1]
        bind = values[2] == 1
    }

    init(from data: Data) {
        self.init(from: data.extract(UInt32.self))
    }
}
