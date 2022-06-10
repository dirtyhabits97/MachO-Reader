import Foundation
import MachO

// Source:
// /Applications/Xcode.13.3.0.13E113.app/...Developer/SDKs/iPhoneOS.sdk/usr/include/mach-o/loader.h

/**
 * The segment load command indicates that a part of this file is to be
 * mapped into the task's address space.  The size of this segment in memory,
 * vmsize, maybe equal to or larger than the amount to map from this file,
 * filesize.  The file is mapped starting at fileoff to the beginning of
 * the segment in memory, vmaddr.  The rest of the memory of the segment,
 * if any, is allocated zero fill on demand.  The segment's maximum virtual
 * memory protection and initial virtual memory protection are specified
 * by the maxprot and initprot fields.  If the segment has sections then the
 * section structures directly follow the segment command and their size is
 * reflected in cmdsize.
 */
struct SegmentCommand {

    // MARK: - Properties

    // TODO: consider making this into a protocol to easily convert between SegmentCommand
    // and LoadCommand. Something like LoadCommandBuildable.asLoadCommand() -> LoadCommand
    // TODO: consider storing the data in a class to avoid copying it all the time
    private let loadCommand: LoadCommand

    var cmd: Cmd { loadCommand.cmd }
    var cmdsize: UInt32 { loadCommand.cmdsize }

    let segname: String

    let vmaddr: UInt64
    let vmsize: UInt64
    let fileoff: UInt64
    let filesize: UInt64
    let maxprot: vm_prot_t
    let initprot: vm_prot_t
    let nsects: UInt32
    let flags: UInt32

    private(set) var sections: [Section] = []

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        if loadCommand.cmd == .segment64 {
            var segmentCommand = loadCommand.data.extract(segment_command_64.self)
            if loadCommand.isSwapped {
                swap_segment_command_64(&segmentCommand, kByteSwapOrder)
            }
            self.init(segmentCommand, loadCommand: loadCommand)
        } else {
            var segmentCommand = loadCommand.data.extract(segment_command.self)
            if loadCommand.isSwapped {
                swap_segment_command(&segmentCommand, kByteSwapOrder)
            }
            self.init(segmentCommand, loadCommand: loadCommand)
        }
    }

    // struct segment_command { /* for 32-bit architectures */
    //   uint32_t	cmd;		/* LC_SEGMENT */
    //   uint32_t	cmdsize;	/* includes sizeof section structs */
    //   char		segname[16];	/* segment name */
    //   uint32_t	vmaddr;		/* memory address of this segment */
    //   uint32_t	vmsize;		/* memory size of this segment */
    //   uint32_t	fileoff;	/* file offset of this segment */
    //   uint32_t	filesize;	/* amount to map from the file */
    //   vm_prot_t	maxprot;	/* maximum VM protection */
    //   vm_prot_t	initprot;	/* initial VM protection */
    //   uint32_t	nsects;		/* number of sections in segment */
    //   uint32_t	flags;		/* flags */
    // };
    private init(_ segmentCommand: segment_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        segname = String(char16: segmentCommand.segname)
        vmaddr = UInt64(segmentCommand.vmaddr)
        vmsize = UInt64(segmentCommand.vmsize)
        fileoff = UInt64(segmentCommand.fileoff)
        filesize = UInt64(segmentCommand.filesize)
        maxprot = segmentCommand.maxprot
        initprot = segmentCommand.initprot
        nsects = segmentCommand.nsects
        flags = segmentCommand.flags

        // build sections
        sections.reserveCapacity(Int(segmentCommand.nsects))

        var offset = MemoryLayout.size(ofValue: segmentCommand)
        for _ in 0 ..< segmentCommand.nsects {
            let data = loadCommand.data.advanced(by: offset)
            let section = Section(data.extract(section.self))
            sections.append(section)
            offset += MemoryLayout<section>.size
        }
    }

    // struct segment_command_64 { /* for 64-bit architectures */
    //   uint32_t	cmd;		/* LC_SEGMENT_64 */
    //   uint32_t	cmdsize;	/* includes sizeof section_64 structs */
    //   char		segname[16];	/* segment name */
    //   uint64_t	vmaddr;		/* memory address of this segment */
    //   uint64_t	vmsize;		/* memory size of this segment */
    //   uint64_t	fileoff;	/* file offset of this segment */
    //   uint64_t	filesize;	/* amount to map from the file */
    //   vm_prot_t	maxprot;	/* maximum VM protection */
    //   vm_prot_t	initprot;	/* initial VM protection */
    //   uint32_t	nsects;		/* number of sections in segment */
    //   uint32_t	flags;		/* flags */
    // };
    private init(_ segmentCommand: segment_command_64, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        segname = String(char16: segmentCommand.segname)
        vmaddr = segmentCommand.vmaddr
        vmsize = segmentCommand.vmsize
        fileoff = segmentCommand.fileoff
        filesize = segmentCommand.filesize
        maxprot = segmentCommand.maxprot
        initprot = segmentCommand.initprot
        nsects = segmentCommand.nsects
        flags = segmentCommand.flags

        // build sections
        sections.reserveCapacity(Int(segmentCommand.nsects))

        var offset = MemoryLayout.size(ofValue: segmentCommand)
        for _ in 0 ..< segmentCommand.nsects {
            let data = loadCommand.data.advanced(by: offset)
            let section = Section(data.extract(section_64.self))
            sections.append(section)
            offset += MemoryLayout<section_64>.size
        }
    }
}

extension SegmentCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        return .segmentCommand(SegmentCommand(from: loadCommand))
    }
}

extension SegmentCommand {

    /**
     * A segment is made up of zero or more sections.  Non-MH_OBJECT files have
     * all of their segments with the proper sections in each, and padded to the
     * specified segment alignment when produced by the link editor.  The first
     * segment of a MH_EXECUTE and MH_FVMLIB format file contains the mach_header
     * and load commands of the object file before its first section.  The zero
     * fill sections are always last in their segment (in all formats).  This
     * allows the zeroed segment padding to be mapped into memory where zero fill
     * sections might be. The gigabyte zero fill sections, those with the section
     * type S_GB_ZEROFILL, can only be in a segment with sections of this type.
     * These segments are then placed after all other segments.
     *
     * The MH_OBJECT format has all of its sections in one segment for
     * compactness.  There is no padding to a specified segment boundary and the
     * mach_header and load commands are not part of the segment.
     *
     * Sections with the same section name, sectname, going into the same segment,
     * segname, are combined by the link editor.  The resulting section is aligned
     * to the maximum alignment of the combined sections and is the new section's
     * alignment.  The combined sections are aligned to their original alignment in
     * the combined section.  Any padded bytes to get the specified alignment are
     * zeroed.
     *
     * The format of the relocation entries referenced by the reloff and nreloc
     * fields of the section structure for mach object files is described in the
     * header file <reloc.h>.
     */
    struct Section {

        let sectname: String
        let segname: String

        let addr: UInt64
        let size: UInt64

        let offset: UInt32
        let align: UInt32
        let reloff: UInt32
        let nreloc: UInt32
        let flags: UInt32
        let reserved1: UInt32
        let reserved2: UInt32
        let reserved3: UInt32?

        // struct section { /* for 32-bit architectures */
        //   char		sectname[16];	/* name of this section */
        //   char		segname[16];	/* segment this section goes in */
        //   uint32_t	addr;		/* memory address of this section */
        //   uint32_t	size;		/* size in bytes of this section */
        //   uint32_t	offset;		/* file offset of this section */
        //   uint32_t	align;		/* section alignment (power of 2) */
        //   uint32_t	reloff;		/* file offset of relocation entries */
        //   uint32_t	nreloc;		/* number of relocation entries */
        //   uint32_t	flags;		/* flags (section type and attributes)*/
        //   uint32_t	reserved1;	/* reserved (for offset or index) */
        //   uint32_t	reserved2;	/* reserved (for count or sizeof) */
        // };
        init(_ section: section) {
            sectname = String(char16: section.sectname)
            segname = String(char16: section.segname)
            addr = UInt64(section.addr)
            size = UInt64(section.size)
            offset = section.offset
            align = section.align
            reloff = section.reloff
            nreloc = section.nreloc
            flags = section.flags
            reserved1 = section.reserved1
            reserved2 = section.reserved2
            reserved3 = nil
        }

        // struct section_64 { /* for 64-bit architectures */
        //   char		sectname[16];	/* name of this section */
        //   char		segname[16];	/* segment this section goes in */
        //   uint64_t	addr;		/* memory address of this section */
        //   uint64_t	size;		/* size in bytes of this section */
        //   uint32_t	offset;		/* file offset of this section */
        //   uint32_t	align;		/* section alignment (power of 2) */
        //   uint32_t	reloff;		/* file offset of relocation entries */
        //   uint32_t	nreloc;		/* number of relocation entries */
        //   uint32_t	flags;		/* flags (section type and attributes)*/
        //   uint32_t	reserved1;	/* reserved (for offset or index) */
        //   uint32_t	reserved2;	/* reserved (for count or sizeof) */
        //   uint32_t	reserved3;	/* reserved */
        // };
        init(_ section: section_64) {
            sectname = String(char16: section.sectname)
            segname = String(char16: section.segname)
            addr = section.addr
            size = section.size
            offset = section.offset
            align = section.align
            reloff = section.reloff
            nreloc = section.nreloc
            flags = section.flags
            reserved1 = section.reserved1
            reserved2 = section.reserved2
            reserved3 = section.reserved3
        }
    }
}

extension SegmentCommand: CustomStringConvertible {

    // TODO: replace this with cli
    var description: String {
        var str = "segname: \(segname)".padding(toLength: 30, withPad: " ", startingAt: 0)
        str += "file: \(String(hex: fileoff))-\(String(hex: fileoff + filesize))"
        str += "   "
        str += "vm: \(String(hex: vmaddr))-\(String(hex: vmaddr + vmsize))"
        str += "   "
        str += "prot: \(initprot)/\(maxprot)"
        return str
    }
}
