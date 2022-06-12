import MachOReaderLib

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
        str += "flags: \(flags.cli)"
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
            str += "\n\(command.commandType().cliCompact)"
        }

        return str
    }
}
