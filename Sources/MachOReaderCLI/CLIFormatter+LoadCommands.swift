import Foundation
import MachOReaderLib

extension LoadCommand: CLIOutput {

    var cli: String {
        var str = cmd.cliCompact.padding(24)
        str += "cmdsize: \(String(cmdsize).padding(8))"
        return str
    }
}

extension CLIOutput where Self: LoadCommandTransformable {

    var prefix: String { asLoadCommand().cliCompact }
}

extension BuildVersionCommand: CLIOutput {

    var cliCompact: String {
        prefix + "platform: \(platform.cliCompact)   minos: \(minOS)   sdk: \(sdk)"
    }

    var cli: String {
        var str = cliCompact

        for (idx, tool) in buildToolVersions.enumerated() {
            str += "\n    [\(idx)] "
            str += "tool: \(tool.tool.readableValue ?? String(tool.tool.rawValue))"
            str += "   "
            str += "version: \(tool.version)"
        }

        return str
    }
}

extension DylibCommand: CLIOutput {

    var cli: String { prefix + dylib.name }
}

extension DylinkerCommand: CLIOutput {

    var cli: String { prefix + name }
}

extension DysymtabCommand: CLIOutput {

    var cli: String {
        var str = prefix
        // swiftformat:disable:next redundantSelf
        str += "nlocalsym: \(self.nlocalsym)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "nextdefsym: \(self.nextdefsym)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "nundefsym: \(self.nundefsym)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "nindirectsyms: \(self.nindirectsyms)"
        return str
    }
}

extension EntryPointCommand: CLIOutput {

    var cli: String {
        var str = prefix
        // swiftformat:disable:next redundantSelf
        str += "entryoff: \(String(hex: self.entryoff)) (\(self.entryoff))"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "stacksize: \(self.stacksize)"
        return str
    }
}

extension LinkedItDataCommand: CLIOutput {

    var cli: String {
        var str = prefix
        // swiftformat:disable:next redundantSelf
        str += "dataoff: \(String(hex: self.dataoff)) (\(self.dataoff))"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "datasize: \(self.datasize)"
        return str
    }
}

extension SegmentCommand: CLIOutput {

    var cliCompact: String {
        var str = prefix
        str += "segname: \(segname.padding(16))"
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
            str += "addr: \(String(hex: section.addr))-\(String(hex: section.addr + section.size))"
            str += "    "
            str += section.sectname.padding(25)
            str += "align: 2^\(section.align) (\(2 << section.align))"
            str += "   "
            str += "flags: \(String.flags(section.flags))"
            str += "   "
            str += "offset: \(section.offset)"
        }

        return str
    }
}

extension SourceVersionCommand: CLIOutput {

    var cli: String {
        prefix + "\(version.A).\(version.B).\(version.C).\(version.D).\(version.E)"
    }
}

extension SymtabCommand: CLIOutput {

    var cli: String {
        var str = prefix
        // swiftformat:disable:next redundantSelf
        str += "symoff: \(self.symoff)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "nsyms: \(self.nsyms)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "stroff: \(self.stroff)"
        str += "   "
        // swiftformat:disable:next redundantSelf
        str += "strsize: \(self.strsize)"
        return str
    }
}

extension ThreadCommand: CLIOutput {

    // TODO: get more info from this
    var cli: String { prefix }
}

extension UUIDCommand: CLIOutput {

    var cli: String { prefix + uuid.uuidString }
}

extension DyldInfoCommand: CLIOutput {
    var cliCompact: String {
        var str = prefix
        str += "rebase_size: \(self.bind_size)"
        str += "   "
        str += "bind_size: \(self.bind_size)"
        str += "   "
        str += "export_size: \(self.export_size)"
        return str
    }

    var cli: String {
        prefix
    }
}

extension LoadCommandType: CLIOutput {

    var cli: String {
        switch self {
        case let .buildVersionCommand(command):
            return command.cli
        case let .dyldInfoCommand(command):
            return command.cli
        case let .dylibCommand(command):
            return command.cli
        case let .dylinkerCommand(command):
            return command.cli
        case let .dysymtabCommand(command):
            return command.cli
        case let .entryPointCommand(command):
            return command.cli
        case let .linkedItDataCommand(command):
            return command.cli
        case let .segmentCommand(command):
            return command.cli
        case let .symtabCommand(command):
            return command.cli
        case let .sourceVersionCommand(command):
            return command.cli
        case let .threadCommand(command):
            return command.cli
        case let .uuidCommand(command):
            return command.cli
        case let .unspecified(command):
            return command.cli
        }
    }

    var cliCompact: String {
        switch self {
        case let .buildVersionCommand(command):
            return command.cliCompact
        case let .dyldInfoCommand(command):
            return command.cliCompact
        case let .dylibCommand(command):
            return command.cliCompact
        case let .dylinkerCommand(command):
            return command.cliCompact
        case let .dysymtabCommand(command):
            return command.cliCompact
        case let .entryPointCommand(command):
            return command.cliCompact
        case let .linkedItDataCommand(command):
            return command.cliCompact
        case let .segmentCommand(command):
            return command.cliCompact
        case let .symtabCommand(command):
            return command.cliCompact
        case let .sourceVersionCommand(command):
            return command.cliCompact
        case let .threadCommand(command):
            return command.cliCompact
        case let .uuidCommand(command):
            return command.cliCompact
        case let .unspecified(command):
            return command.cliCompact
        }
    }
}
