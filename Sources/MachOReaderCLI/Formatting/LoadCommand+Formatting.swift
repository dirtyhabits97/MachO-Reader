import Foundation
import MachOReaderLib

// swiftformat:disable redundantSelf

extension LoadCommand: CLIOutput {

    var summary: String {
        [
            cmd.summary.padding(24),
            "cmdsize: \(String(cmdsize).padding(8))",
        ]
        .joined()
    }
}

extension CLIOutput where Self: LoadCommandTransformable {

    var prefix: String { asLoadCommand().summary }
}

extension BuildVersionCommand: CLIOutput {

    var summary: String {
        prefix + "platform: \(platform.summary)   minos: \(minOS)   sdk: \(sdk)"
    }

    var detailed: [String] {
        var output = [summary]

        for (idx, tool) in buildToolVersions.enumerated() {
            output.append("\n    [\(idx)] ")
            output.append("tool: \(tool.tool.readableValue ?? String(tool.tool.rawValue))")
            output.append("   ")
            output.append("version: \(tool.version)")
        }

        return output
    }
}

extension DylibCommand: CLIOutput {

    var summary: String { prefix + dylib.name }
}

extension DylinkerCommand: CLIOutput {

    var summary: String { prefix + name }
}

extension DysymtabCommand: CLIOutput {

    var summary: String {
        [
            prefix,
            "nlocalsym: \(self.nlocalsym)",
            "   ",
            "nextdefsym: \(self.nextdefsym)",
            "   ",
            "nundefsym: \(self.nundefsym)",
            "   ",
            "nindirectsyms: \(self.nindirectsyms)",
        ]
        .joined()
    }
}

extension EntryPointCommand: CLIOutput {

    var summary: String {
        [
            prefix,
            "entryoff: \(String(hex: self.entryoff)) (\(self.entryoff))",
            "   ",
            "stacksize: \(self.stacksize)",
        ]
        .joined()
    }
}

extension LinkedItDataCommand: CLIOutput {

    var summary: String {
        [
            prefix,
            "dataoff: \(String(hex: self.dataoff)) (\(self.dataoff))",
            "   ",
            "datasize: \(self.datasize)",
        ]
        .joined()
    }
}

extension SegmentCommand: CLIOutput {

    var summary: String {
        [
            prefix,
            "segname: \(segname.padding(16))",
            "file: \(String(hex: fileoff))-\(String(hex: fileoff + filesize))",
            "   ",
            "vm: \(String(hex: vmaddr))-\(String(hex: vmaddr + vmsize))",
            "   ",
            "prot: \(initprot)/\(maxprot)",
        ]
        .joined()
    }

    var detailed: [String] {
        var output = [summary]

        for (idx, section) in sections.enumerated() {
            output.append(contentsOf: [
                "\n    [\(idx)] ",
                "addr: \(String(hex: section.addr))-\(String(hex: section.addr + section.size))",
                "    ",
                section.sectname.padding(25),
                "align: 2^\(section.align) (\(2 << section.align))",
                "   ",
                "flags: \(String.flags(section.flags))",
                "   ",
                "offset: \(section.offset)",
            ])
        }

        return output
    }
}

extension SourceVersionCommand: CLIOutput {

    var summary: String {
        prefix + "\(version.A).\(version.B).\(version.C).\(version.D).\(version.E)"
    }
}

extension SymtabCommand: CLIOutput {

    var summary: String {
        [
            prefix,
            "symoff: \(self.symoff)",
            "   ",
            "nsyms: \(self.nsyms)",
            "   ",
            "stroff: \(self.stroff)",
            "   ",
            "strsize: \(self.strsize)",
        ]
        .joined()
    }
}

extension ThreadCommand: CLIOutput {

    // TODO: get more info from this
    var summary: String { prefix }
}

extension UUIDCommand: CLIOutput {

    var summary: String { prefix + uuid.uuidString }
}

extension DyldInfoCommand: CLIOutput {

    var summary: String { prefix }

    var detailed: [String] {
        [
            prefix, "\n",
            "rebase: \(String(hex: self.rebase_off))-\(String(hex: self.rebase_off + self.rebase_size))(\(self.rebase_size))",
            "\n",
            "bind: \(String(hex: self.bind_off))-\(String(hex: self.bind_off + self.bind_size))(\(self.bind_size))",
            "\n",
            "weak_bind: \(String(hex: self.weak_bind_off))-\(String(hex: self.weak_bind_off + self.weak_bind_size))(\(self.weak_bind_off))",
        ]
    }
}

extension LoadCommandType: CLIOutput {

    var summary: String {
        switch self {
        case let .buildVersionCommand(command):
            return command.summary
        case let .dyldInfoCommand(command):
            return command.summary
        case let .dylibCommand(command):
            return command.summary
        case let .dylinkerCommand(command):
            return command.summary
        case let .dysymtabCommand(command):
            return command.summary
        case let .entryPointCommand(command):
            return command.summary
        case let .linkedItDataCommand(command):
            return command.summary
        case let .segmentCommand(command):
            return command.summary
        case let .symtabCommand(command):
            return command.summary
        case let .sourceVersionCommand(command):
            return command.summary
        case let .threadCommand(command):
            return command.summary
        case let .uuidCommand(command):
            return command.summary
        case let .unspecified(command):
            return command.summary
        }
    }

    var detailed: [String] {
        switch self {
        case let .buildVersionCommand(command):
            return command.detailed
        case let .dyldInfoCommand(command):
            return command.detailed
        case let .dylibCommand(command):
            return command.detailed
        case let .dylinkerCommand(command):
            return command.detailed
        case let .dysymtabCommand(command):
            return command.detailed
        case let .entryPointCommand(command):
            return command.detailed
        case let .linkedItDataCommand(command):
            return command.detailed
        case let .segmentCommand(command):
            return command.detailed
        case let .symtabCommand(command):
            return command.detailed
        case let .sourceVersionCommand(command):
            return command.detailed
        case let .threadCommand(command):
            return command.detailed
        case let .uuidCommand(command):
            return command.detailed
        case let .unspecified(command):
            return command.detailed
        }
    }
}

// swiftformat:enable redundantSelf
