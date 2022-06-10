import Foundation

// Source:
// /Applications/Xcode.13.3.0.13E113.app/.../usr/include/mach-o/loader.h
struct MachOHeader {

    // MARK: - Properties

    let size: Int

    let magic: Magic
    let cputype: CPUType
    let filetype: FileType
    let ncmds: UInt32
    let sizeofcmds: UInt32
    let flags: UInt32

    // MARK: - Lifecycle

    init(from data: Data) {
        let magic = Magic(peek: data)

        if magic.isMagic64 {
            var header = data.extract(mach_header_64.self)

            if magic.isSwapped {
                swap_mach_header_64(&header, kByteSwapOrder)
            }

            self.init(header, magic: magic)
        } else {
            var header = data.extract(mach_header.self)

            if magic.isSwapped {
                swap_mach_header(&header, kByteSwapOrder)
            }

            self.init(header, magic: magic)
        }
    }

    // struct mach_header {
    //     uint32_t	magic;		/* mach magic number identifier */
    //     cpu_type_t	cputype;	/* cpu specifier */
    //     cpu_subtype_t	cpusubtype;	/* machine specifier */
    //     uint32_t	filetype;	/* type of file */
    //     uint32_t	ncmds;		/* number of load commands */
    //     uint32_t	sizeofcmds;	/* the size of all the load commands */
    //     uint32_t	flags;		/* flags */
    // };
    init(_ rawValue: mach_header, magic: Magic) {
        self.magic = magic
        size = MemoryLayout.size(ofValue: rawValue)
        cputype = CPUType(rawValue.cputype)
        filetype = FileType(rawValue.filetype)
        ncmds = rawValue.ncmds
        sizeofcmds = rawValue.sizeofcmds
        flags = rawValue.flags
    }

    // struct mach_header_64 {
    //     uint32_t	magic;		/* mach magic number identifier */
    //     cpu_type_t	cputype;	/* cpu specifier */
    //     cpu_subtype_t	cpusubtype;	/* machine specifier */
    //     uint32_t	filetype;	/* type of file */
    //     uint32_t	ncmds;		/* number of load commands */
    //     uint32_t	sizeofcmds;	/* the size of all the load commands */
    //     uint32_t	flags;		/* flags */
    //     uint32_t	reserved;	/* reserved */
    // };
    init(_ rawValue: mach_header_64, magic: Magic) {
        self.magic = magic
        size = MemoryLayout.size(ofValue: rawValue)
        cputype = CPUType(rawValue.cputype)
        filetype = FileType(rawValue.filetype)
        ncmds = rawValue.ncmds
        sizeofcmds = rawValue.sizeofcmds
        flags = rawValue.flags
    }
}
