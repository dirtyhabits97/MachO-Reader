import Foundation

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
        let readable: String
        switch self {
        case .x86: readable = "x86"
        case .x86_64: readable = "x86_64"
        case .arm: readable = "ARM"
        case .arm_64: readable = "ARM64"
        default: return String(rawValue)
        }
        return "\(readable.padding(toLength: 7, withPad: " ", startingAt: 0)) (\(rawValue))"
    }

    var cliCompact: String { readableValue }
}

extension Magic: CLIOutput {

    var cli: String {
        let pretty: String
        switch self {
        case .fatMagic: pretty = "FAT_MAGIC"
        case .fatCigam: pretty = "FAT_CIGAM"
        case .fatMagic64: pretty = "FAT_MAGIC_64"
        case .fatCigam64: pretty = "FAT_CIGAM_64"
        case .magic: pretty = "MH_MAGIC"
        case .cigam: pretty = "MH_CIGAM"
        case .magic64: pretty = "MH_MAGIC_64"
        case .cigam64: pretty = "MH_CIGAM_64"
        default: return String.magic(rawValue)
        }
        return "\(pretty) (\(String.magic(rawValue)))"
    }
}

extension MachOHeader: CLIOutput {

    var cli: String {
        var str = "MACH_HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
        str += "magic: \(magic.cli)"
        str += "   "
        str += "cputype: \(cputype.cliCompact)"
        str += "   "
        str += "filetype: \(filetype.description)"
        str += "   "
        str += "ncmds: \(ncmds)"
        str += "   "
        str += "sizeofcmds: \(sizeofcmds)"
        str += "\n".padding(toLength: 21, withPad: " ", startingAt: 0)
        str += "flags: \(String.flags(flags))"
        return str
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
        var str = "segname: \(self.segname)".padding(toLength: 30, withPad: " ", startingAt: 0)
        switch underlyingValue {
        case .segment(let command):
            str += "file: \(String(hex: command.fileoff))-\(String(hex: command.fileoff + command.filesize))"
            str += "   "
            str += "vm: \(String(hex: command.vmaddr))-\(String(hex: command.vmaddr + command.vmsize))"
            str += "   "
            str += "prot: \(command.initprot)/\(command.maxprot)"
        case .segment64(let command):
            str += "file: \(String(hex: command.fileoff))-\(String(hex: command.fileoff + command.filesize))"
            str += "   "
            str += "vm: \(String(hex: command.vmaddr))-\(String(hex: command.vmaddr + command.vmsize))"
            str += "   "
            str += "prot: \(command.initprot)/\(command.maxprot)"
        }
        return str
    }

    var cli: String {
        var str = cliCompact

        for (idx, section)in sections.enumerated() {
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
