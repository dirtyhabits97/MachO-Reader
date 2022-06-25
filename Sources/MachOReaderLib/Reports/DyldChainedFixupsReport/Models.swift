import Foundation

// struct dyld_chained_fixups_header
// {
//     uint32_t    fixups_version;    // 0
//     uint32_t    starts_offset;     // offset of dyld_chained_starts_in_image in chain_data
//     uint32_t    imports_offset;    // offset of imports table in chain_data
//     uint32_t    symbols_offset;    // offset of symbol strings in chain_data
//     uint32_t    imports_count;     // number of imported symbol names
//     uint32_t    imports_format;    // DYLD_CHAINED_IMPORT*
//     uint32_t    symbols_format;    // 0 => uncompressed, 1 => zlib compressed
// };
public struct DyldChainedFixupsHeader {
    public let fixupsVersion: UInt32
    public let startsOffset: UInt32
    public let importsOffset: UInt32
    public let symbolsOffset: UInt32
    public let importsCount: UInt32
    // TODO: Create a cmodel for this and transform these 2 properties into raw representable constants.
    public let importsFormat: UInt32
    public let symbolsFormat: UInt32
}

// This struct is embedded in LC_DYLD_CHAINED_FIXUPS payload
// struct dyld_chained_starts_in_image
// {
//     uint32_t    seg_count;
//     uint32_t    seg_info_offset[1];  // each entry is offset into this struct for that segment
//     // followed by pool of dyld_chain_starts_in_segment data
// };
// TODO: move this back to cmodels, we don't need to present this data in the report
public struct DyldChainedStartsInImage: CustomExtractable {

    public let segCount: UInt32
    public let segInfoOffset: [UInt32]

    init(from data: Data) {
        segCount = data.extract(UInt32.self)
        segInfoOffset = data
            .advanced(by: MemoryLayout.size(ofValue: segCount))
            .extractArray(UInt32.self, count: Int(segCount))
    }
}
