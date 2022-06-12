import Foundation
import MachOReaderLib

extension Platform: CLIOutput {

    var cli: String {
        readableValue ?? String(rawValue)
    }
}

extension BuildVersionCommand: CLIOutput {

    var cliCompact: String {
        "platform: \(platform.cliCompact)   minos: \(minOS)   sdk: \(sdk)"
    }

    var cli: String {
        // var str = cmd.cliCompact
        // str += "   "
        // str += cliCompact

        // for (idx, section) in sections.enumerated() {
        //     str += "\n    [\(idx)] "
        //     str += section.sectname.padding(toLength: 35, withPad: " ", startingAt: 0)
        //     str += "addr: \(String(hex: section.addr))-\(String(hex: section.addr + section.size))"
        //     str += "   "
        //     str += "flags: \(String.flags(section.flags))"
        //     str += "   "
        //     str += "align: 2^\(section.align) (\(2 << section.align))"
        //     str += "   "
        //     str += "offset: \(section.offset)"
        // }

        // return str
        var str = cmd.cliCompact
        str += "  "
        str += cliCompact

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

    var cli: String {
        var str = cmd.cliCompact.padding(toLength: 24, withPad: " ", startingAt: 0)
        str += dylib.name
        return str
    }

    var cliCompact: String { dylib.name }
}

extension DylinkerCommand: CLIOutput {

    var cli: String { name }
}

extension DysymtabCommand: CLIOutput {

    var cli: String {
        // swiftformat:disable:next redundantSelf
        var str = "nlocalsym: \(self.nlocalsym)"
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
        // swiftformat:disable:next redundantSelf
        "entryoff: \(String(hex: self.entryoff)) (\(self.entryoff))   stacksize: \(self.stacksize)"
    }
}

extension LinkedItDataCommand: CLIOutput {

    var cli: String {
        // swiftformat:disable:next redundantSelf
        "dataoff: \(String(hex: self.dataoff)) (\(self.dataoff))   datasize: \(self.datasize)"
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
        var str = cmd.cliCompact
        str += "   "
        str += cliCompact

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

extension SourceVersionCommand: CLIOutput {

    var cli: String {
        "\(version.A).\(version.B).\(version.C).\(version.D).\(version.E)"
    }
}

extension SymtabCommand: CLIOutput {

    var cli: String {
        // swiftformat:disable:next redundantSelf
        "symoff: \(self.symoff)   nsyms: \(self.nsyms)   stroff: \(self.stroff)   strsize: \(self.strsize)"
    }
}

extension ThreadCommand: CLIOutput {

    // TODO: get more info from this
    var cli: String { "" }
}

extension UUIDCommand: CLIOutput {

    var cli: String { uuid.uuidString }
}

extension LoadCommandType: CLIOutput {

    var cli: String {
        switch self {
        case let .buildVersionCommand(command):
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
        case .threadCommand:
            return ""
        case let .uuidCommand(command):
            return command.cli
        case .unspecified:
            return ""
        }
    }

    var cliCompact: String {
        switch self {
        case let .buildVersionCommand(command):
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
        case .threadCommand:
            return ""
        case let .uuidCommand(command):
            return command.cliCompact
        case .unspecified:
            return ""
        }
    }
}
