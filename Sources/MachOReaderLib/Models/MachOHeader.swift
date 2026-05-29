import Foundation

/// Source:
/// /Applications/Xcode.13.3.0.13E113.app/.../usr/include/mach-o/loader.h
public struct MachOHeader {

    // MARK: - Properties

    let size: Int

    public let magic: Magic
    public let cputype: CPUType
    public let filetype: FileType
    public let ncmds: UInt32
    public let sizeofcmds: UInt32
    public let flags: Flags

    // MARK: - Lifecycle

    init(from data: Data) {
        let magic = Magic(peek: data)

        if magic.isMagic64 {
            guard var header = try? data.decode(mach_header_64.self, at: 0) else {
                fatalError("Failed to decode mach_header_64 from data of size \(data.count)")
            }

            if magic.isSwapped {
                swap_mach_header_64(&header, kByteSwapOrder)
            }

            self.init(header, magic: magic)
        } else {
            guard var header = try? data.decode(mach_header.self, at: 0) else {
                fatalError("Failed to decode mach_header from data of size \(data.count)")
            }

            if magic.isSwapped {
                swap_mach_header(&header, kByteSwapOrder)
            }

            self.init(header, magic: magic)
        }
    }

    /// struct mach_header {
    ///     uint32_t	magic;		/* mach magic number identifier */
    ///     cpu_type_t	cputype;	/* cpu specifier */
    ///     cpu_subtype_t	cpusubtype;	/* machine specifier */
    ///     uint32_t	filetype;	/* type of file */
    ///     uint32_t	ncmds;		/* number of load commands */
    ///     uint32_t	sizeofcmds;	/* the size of all the load commands */
    ///     uint32_t	flags;		/* flags */
    /// };
    private init(_ rawValue: mach_header, magic: Magic) {
        self.magic = magic
        size = MemoryLayout.size(ofValue: rawValue)
        cputype = CPUType(rawValue.cputype)
        filetype = FileType(rawValue.filetype)
        ncmds = rawValue.ncmds
        sizeofcmds = rawValue.sizeofcmds
        flags = Flags(rawValue.flags)
    }

    /// struct mach_header_64 {
    ///     uint32_t	magic;		/* mach magic number identifier */
    ///     cpu_type_t	cputype;	/* cpu specifier */
    ///     cpu_subtype_t	cpusubtype;	/* machine specifier */
    ///     uint32_t	filetype;	/* type of file */
    ///     uint32_t	ncmds;		/* number of load commands */
    ///     uint32_t	sizeofcmds;	/* the size of all the load commands */
    ///     uint32_t	flags;		/* flags */
    ///     uint32_t	reserved;	/* reserved */
    /// };
    private init(_ rawValue: mach_header_64, magic: Magic) {
        self.magic = magic
        size = MemoryLayout.size(ofValue: rawValue)
        cputype = CPUType(rawValue.cputype)
        filetype = FileType(rawValue.filetype)
        ncmds = rawValue.ncmds
        sizeofcmds = rawValue.sizeofcmds
        flags = Flags(rawValue.flags)
    }
}
