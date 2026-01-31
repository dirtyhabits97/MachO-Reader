import Foundation
import MachO

/**
 * This header file describes the structures of the file format for "fat"
 * architecture specific file (wrapper design).  At the begining of the file
 * there is one fat_header structure followed by a number of fat_arch
 * structures.  For each architecture in the file, specified by a pair of
 * cputype and cpusubtype, the fat_header describes the file offset, file
 * size and alignment in the file of the architecture specific member.
 * The padded bytes in the file to place each member on it's specific alignment
 * are defined to be read as zeros and can be left as "holes" if the file system
 * can support them as long as they read as zeros.
 *
 * All structures defined here are always written and read to/from disk
 * in big-endian order.
 */
public struct MachOFatHeader {

    // MARK: - Properties

    public let magic: Magic
    // swiftlint:disable:next identifier_name
    public let nfat_arc: UInt32
    public let archs: [Architecture]

    // MARK: - Lifecycle

    init?(from data: Data) {
        let magic = Magic(peek: data)

        guard magic.isFat else { return nil }

        var fatHeader = data.extract(fat_header.self)
        if magic.isSwapped {
            swap_fat_header(&fatHeader, kByteSwapOrder)
        }

        self.init(fatHeader: fatHeader, magic: magic, data: data)
    }

    /// struct fat_header {
    ///   uint32_t	magic;		/* FAT_MAGIC or FAT_MAGIC_64 */
    ///   uint32_t	nfat_arch;	/* number of structs that follow */
    /// };
    private init(fatHeader: fat_header, magic: Magic, data: Data) {
        self.magic = magic
        nfat_arc = fatHeader.nfat_arch

        // build arch array
        var archs: [Architecture] = []
        var offset = MemoryLayout.size(ofValue: fatHeader)

        for _ in 0 ..< fatHeader.nfat_arch {
            if magic.isMagic64 {
                var fatArch = data.advanced(by: offset).extract(fat_arch_64.self)
                if magic.isSwapped {
                    swap_fat_arch_64(&fatArch, 1, kByteSwapOrder)
                }
                offset += MemoryLayout.size(ofValue: fatArch)
                archs.append(Architecture(fatArch))
            } else {
                var fatArch = data.advanced(by: offset).extract(fat_arch.self)
                if magic.isSwapped {
                    swap_fat_arch(&fatArch, 1, kByteSwapOrder)
                }
                offset += MemoryLayout.size(ofValue: fatArch)
                archs.append(Architecture(fatArch))
            }
        }

        self.archs = archs
    }

    // MARK: - Methods

    func offset(for cputype: CPUType? = nil) -> UInt64 {
        archs.first(where: { $0.cputype == cputype })?.offset
            ?? archs.first?.offset
            ?? 0
    }
}

public extension MachOFatHeader {

    // Source: .../usr/include/mach-o/fat.h
    struct Architecture {

        public let cputype: CPUType
        public let cpuSubtype: CPUSubType
        public let offset: UInt64
        public let size: UInt64
        public let align: UInt32
        public let reserved: UInt32?

        /// struct fat_arch {
        ///   cpu_type_t	cputype;	/* cpu specifier (int) */
        ///   cpu_subtype_t	cpusubtype;	/* machine specifier (int) */
        ///   uint32_t	offset;		/* file offset to this object file */
        ///   uint32_t	size;		/* size of this object file */
        ///   uint32_t	align;		/* alignment as a power of 2 */
        /// };
        init(_ rawValue: fat_arch) {
            cputype = CPUType(rawValue.cputype)
            cpuSubtype = CPUSubType(rawValue.cpusubtype)
            offset = UInt64(rawValue.offset)
            size = UInt64(rawValue.size)
            align = rawValue.align
            reserved = nil
        }

        /// struct fat_arch_64 {
        ///   cpu_type_t	cputype;	/* cpu specifier (int) */
        ///   cpu_subtype_t	cpusubtype;	/* machine specifier (int) */
        ///   uint64_t	offset;		/* file offset to this object file */
        ///   uint64_t	size;		/* size of this object file */
        ///   uint32_t	align;		/* alignment as a power of 2 */
        ///   uint32_t	reserved;	/* reserved */
        /// };
        init(_ rawValue: fat_arch_64) {
            cputype = CPUType(rawValue.cputype)
            cpuSubtype = CPUSubType(rawValue.cpusubtype)
            offset = UInt64(rawValue.offset)
            size = UInt64(rawValue.size)
            align = rawValue.align
            reserved = rawValue.reserved
        }
    }
}
