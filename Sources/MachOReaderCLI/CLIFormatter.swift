import Foundation
import MachOReaderLib

enum CLIFormatter {

    static func print(_ output: CLIOutput) {
        Swift.print(output.cli)
    }
}

protocol CLIOutput {

    var cli: String { get }
    var cliCompact: String { get }
}

extension CLIOutput {

    var cliCompact: String { cli }
}

extension FatHeader: CLIOutput {

    var cli: String {
        var str = "FAT_HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
        str += "magic: \(magic.cli.padding(toLength: 25, withPad: " ", startingAt: 0))"
        str += "nfat_archs: \(archs.count)"

        for (idx, arch) in archs.enumerated() {
            str += "\n    [\(idx)] \(arch.cli)"
        }

        return str
    }
}

extension FatHeader.Architecture: CLIOutput {

    // TODO: for some reason, the cpu subtype is not matching otool
    var cli: String {
        var str = "cputype: \(cputype.cli)".padding(toLength: 30, withPad: " ", startingAt: 0)
        str += "cpusubtype: \(String(cpuSubtype).padding(toLength: 15, withPad: " ", startingAt: 0))"
        str += "offset: \(String(offset).padding(toLength: 10, withPad: " ", startingAt: 0))"
        str += "size: \(String(size).padding(toLength: 10, withPad: " ", startingAt: 0))"
        str += "align: 2^\(align)"
        return str
    }
}

extension CPUType: CLIOutput {

    var cli: String {
        if let readableValue = readableValue {
            return "\(readableValue.padding(toLength: 7, withPad: " ", startingAt: 0)) (\(rawValue))"
        }
        return String(rawValue)
    }

    var cliCompact: String { readableValue ?? String(rawValue) }
}

extension Magic: CLIOutput {

    var cli: String {
        if let readableValue = readableValue {
            return "\(readableValue) \(String.magic(rawValue))"
        }
        return .magic(rawValue)
    }
}

extension FileType: CLIOutput {

    var cli: String {
        readableValue ?? .filetype(rawValue)
    }
}

extension MachOHeader: CLIOutput {

    var cli: String {
        var str = "MACH_HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
        str += "magic: \(magic.cli)"
        str += "   "
        str += "cputype: \(cputype.cliCompact)"
        str += "   "
        str += "filetype: \(filetype.cliCompact)"
        str += "   "
        str += "ncmds: \(ncmds)"
        str += "   "
        str += "sizeofcmds: \(sizeofcmds)"
        str += "\n".padding(toLength: 21, withPad: " ", startingAt: 0)
        str += "flags: \(String.flags(flags))"
        return str
    }
}

extension Cmd: CLIOutput {

    var cli: String {
        readableValue ?? .cmd(rawValue)
    }
}

extension MachOFile: CLIOutput {

    var cli: String {
        var str = ""
        if let fatHeader = fatHeader {
            str += fatHeader.cli
            str += "\n"
            str += "\n"
        }

        str += header.cli
        str += "\n"

        for command in commands {
            str += "\n"
            str += command.cmd.readableValue.padding(toLength: 30, withPad: " ", startingAt: 0)
            str += "cmdsize: \(command.cmdsize)".padding(toLength: 20, withPad: " ", startingAt: 0)
            str += command.commandType().description
        }

        return str
    }
}

extension SegmentCommand: CLIOutput {

    var cliCompact: String {
        var str = "segname: \(segname)".padding(toLength: 30, withPad: " ", startingAt: 0)
        str += "file: \(String(hex: fileoff))-\(String(hex: fileoff + filesize))"
        str += "   "
        str += "vm: \(String(hex: vmaddr))-\(String(hex: vmaddr + vmsize))"
        str += "   "
        str += "prot: \(initprot)/\(maxprot)"
        return str
    }

    var cli: String {
        var str = cliCompact

        for (idx, section) in sections.enumerated() {
            str += "\n    [\(idx)] "
            str += section.sectname.padding(toLength: 35, withPad: " ", startingAt: 0)
            str += "addr: \(String(hex: section.addr))-\(String(hex: section.addr + section.size))"
            str += "   "
            str += "flags: \(String.flags(section.flags))"
            str += "   "
            str += "align: 2^\(section.align) (\(2 << section.align))"
            str += "   "
            str += "offset: \(section.offset)"
        }

        return str
    }
}
