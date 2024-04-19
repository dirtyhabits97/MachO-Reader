import Foundation
import MachOReaderLib

extension MachOFatHeader.Architecture: CLIOutput {

    // TODO: for some reason, the cpu subtype is not matching otool
    var summary: String {
        [
            "cputype: \(cputype.summary)".padding(30),
            "cpusubtype: \(String(cpuSubtype).padding(15))",
            "offset: \(String(offset).padding(10))",
            "size: \(String(size).padding(10))",
            "align: 2^\(align)",
        ]
        .joined()
    }
}

extension MachOFatHeader: CLIOutput {

    var summary: String {
        detailed.joined()
    }

    var detailed: [String] {
        var output = [
            "FAT_HEADER".padding(20),
            "magic: \(magic.summary.padding(25))",
            "nfat_archs: \(archs.count)",
        ]

        for (idx, arch) in archs.enumerated() {
            output.append("\n\t[\(idx)] \(arch.summary)")
        }

        return output
    }
}

extension MachOHeader.Flags: CLIOutput {

    var summary: String {
        readableValue ?? .flags(rawValue)
    }
}

extension MachOHeader: CLIOutput {

    var summary: String {
        detailed.joined()
    }

    var detailed: [String] {
        [
            "MACH_HEADER".padding(20),
            "magic: \(magic.summary)",
            "   ",
            "cputype: \(cputype.summary)",
            "   ",
            "filetype: \(filetype.summary)",
            "   ",
            "ncmds: \(ncmds)",
            "   ",
            "sizeofcmds: \(sizeofcmds)",
            "\n".padding(21),
            "flags: \(flags.summary)",
        ]
    }
}
