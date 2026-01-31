// swiftlint:disable file_length
import Foundation
import MachOReaderLib

/// Formats Mach-O data structures as human-readable text
// swiftlint:disable:next type_body_length
final class TextFormatter {

    // MARK: - Properties

    private let config: FormattingConfig

    // MARK: - Lifecycle

    init(config: FormattingConfig = .default) {
        self.config = config
    }

    // MARK: - MachOFile

    func format(_ file: MachOFile) -> String {
        var output = [String]()

        if let fatHeader = file.fatHeader {
            output.append(format(fatHeader))
            output.append("\n\n")
        }

        output.append(format(file.header))
        output.append("\n")

        for command in file.commands {
            output.append("\n")
            output.append(formatSummary(command.commandType()))
        }

        return output.joined()
    }

    // MARK: - Fat Header

    func format(_ fatHeader: MachOFatHeader) -> String {
        var output = [
            "FAT_HEADER".padding(config.labelWidth),
            "magic: \(formatMagic(fatHeader.magic).padding(25))",
            "nfat_archs: \(fatHeader.archs.count)",
        ]

        for (idx, arch) in fatHeader.archs.enumerated() {
            output.append("\n\(config.indent)[\(idx)] \(format(arch))")
        }

        return output.joined()
    }

    func format(_ arch: MachOFatHeader.Architecture) -> String {
        var output = [
            "cputype: \(formatCPUType(arch.cputype))".padding(config.labelWidth),
        ]

        if let readableCpuSubType = arch.cpuSubtype.readableValue(cpuType: arch.cputype) {
            output.append(contentsOf: [
                "cpusubtype: ",
                "\(arch.cpuSubtype.rawValue)",
                " ",
                "(\(readableCpuSubType))".padding(8),
            ])
        } else {
            output.append(contentsOf: [
                "cpusubtype: ",
                "\(arch.cpuSubtype.rawValue)".padding(8),
            ])
        }

        output.append(contentsOf: [
            "offset: \(String(arch.offset).padding(config.valueWidth))",
            "size: \(String(arch.size).padding(config.valueWidth))",
            "align: 2^\(arch.align)",
        ])

        return output.joined()
    }

    // MARK: - Mach-O Header

    func format(_ header: MachOHeader) -> String {
        [
            "MACH_HEADER".padding(config.labelWidth),
            "cputype: \(formatCPUType(header.cputype))",
            config.fieldSeparator,
            "filetype: \(formatFileType(header.filetype))",
            config.fieldSeparator,
            "ncmds: \(header.ncmds)",
            config.fieldSeparator,
            "sizeofcmds: \(header.sizeofcmds)",
            "\n".padding(config.labelWidth + 1),
            "flags: \(formatFlags(header.flags))",
        ].joined()
    }

    // MARK: - Load Commands

    func format(_ command: LoadCommand) -> String {
        [
            formatCmd(command.cmd).padding(config.commandTypeWidth),
            "cmdsize: \(String(command.cmdsize).padding(8))",
        ].joined()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func formatSummary(_ commandType: LoadCommandType) -> String {
        switch commandType {
        case .buildVersionCommand(let cmd):
            return formatSummary(cmd)
        case .dyldInfoCommand(let cmd):
            return formatSummary(cmd)
        case .dylibCommand(let cmd):
            return formatSummary(cmd)
        case .dylinkerCommand(let cmd):
            return formatSummary(cmd)
        case .dysymtabCommand(let cmd):
            return formatSummary(cmd)
        case .entryPointCommand(let cmd):
            return formatSummary(cmd)
        case .linkedItDataCommand(let cmd):
            return formatSummary(cmd)
        case .segmentCommand(let cmd):
            return formatSummary(cmd)
        case .sourceVersionCommand(let cmd):
            return formatSummary(cmd)
        case .symtabCommand(let cmd):
            return formatSummary(cmd)
        case .threadCommand(let cmd):
            return formatSummary(cmd)
        case .uuidCommand(let cmd):
            return formatSummary(cmd)
        case .unspecified(let cmd):
            return format(cmd)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func formatDetailed(_ commandType: LoadCommandType) -> String {
        switch commandType {
        case .buildVersionCommand(let cmd):
            return formatDetailed(cmd)
        case .dyldInfoCommand(let cmd):
            return formatDetailed(cmd)
        case .dylibCommand(let cmd):
            return formatDetailed(cmd)
        case .dylinkerCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .dysymtabCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .entryPointCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .linkedItDataCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .segmentCommand(let cmd):
            return formatDetailed(cmd)
        case .sourceVersionCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .symtabCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .threadCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .uuidCommand(let cmd):
            return formatSummary(cmd) // No detailed version
        case .unspecified(let cmd):
            return format(cmd)
        }
    }

    // MARK: - Build Version Command

    func formatSummary(_ command: BuildVersionCommand) -> String {
        format(command.asLoadCommand())
            + "platform: \(formatPlatform(command.platform))"
            + config.fieldSeparator
            + "minos: \(command.minOS)"
            + config.fieldSeparator
            + "sdk: \(command.sdk)"
    }

    func formatDetailed(_ command: BuildVersionCommand) -> String {
        var output = [formatSummary(command)]

        for (idx, tool) in command.buildToolVersions.enumerated() {
            output.append("\n\(config.indent)[\(idx)] ")
            output.append("tool: \(tool.tool.readableValue ?? String(tool.tool.rawValue))")
            output.append(config.fieldSeparator)
            output.append("version: \(tool.version)")
        }

        return output.joined()
    }

    // MARK: - Dylib Command

    func formatSummary(_ command: DylibCommand) -> String {
        format(command.asLoadCommand()) + command.dylib.name
    }

    func formatDetailed(_ command: DylibCommand) -> String {
        let indent = "\n\(config.indent)"
        return [
            format(command.asLoadCommand()),
            indent, "name:".padding(32), command.dylib.name,
            indent, "timestamp:".padding(32), String(describing: command.dylib.timestamp),
            indent, "current_version:".padding(32), String(describing: command.dylib.currentVersion),
            indent, "compatibility_version:".padding(32), String(describing: command.dylib.compatibilityVersion),
        ].joined()
    }

    // MARK: - Dylinker Command

    func formatSummary(_ command: DylinkerCommand) -> String {
        format(command.asLoadCommand()) + command.name
    }

    // MARK: - Dysymtab Command

    func formatSummary(_ command: DysymtabCommand) -> String {
        [
            format(command.asLoadCommand()),
            "nlocalsym: \(command.nlocalsym)",
            config.fieldSeparator,
            "nextdefsym: \(command.nextdefsym)",
            config.fieldSeparator,
            "nundefsym: \(command.nundefsym)",
            config.fieldSeparator,
            "nindirectsyms: \(command.nindirectsyms)",
        ].joined()
    }

    // MARK: - Entry Point Command

    func formatSummary(_ command: EntryPointCommand) -> String {
        [
            format(command.asLoadCommand()),
            "entryoff: \(String(hex: command.entryoff)) (\(command.entryoff))",
            config.fieldSeparator,
            "stacksize: \(command.stacksize)",
        ].joined()
    }

    // MARK: - Linked It Data Command

    func formatSummary(_ command: LinkedItDataCommand) -> String {
        [
            format(command.asLoadCommand()),
            "dataoff: \(String(hex: command.dataoff)) (\(command.dataoff))",
            config.fieldSeparator,
            "datasize: \(command.datasize)",
        ].joined()
    }

    // MARK: - Segment Command

    func formatSummary(_ command: SegmentCommand) -> String {
        [
            format(command.asLoadCommand()),
            "segname: \(command.segname.padding(config.segmentNameWidth))",
            "file: \(String(hex: command.fileoff))-\(String(hex: command.fileoff + command.filesize))",
            config.fieldSeparator,
            "vm: \(String(hex: command.vmaddr))-\(String(hex: command.vmaddr + command.vmsize))",
            config.fieldSeparator,
            "prot: \(command.initprot)/\(command.maxprot)",
        ].joined()
    }

    func formatDetailed(_ command: SegmentCommand) -> String {
        var output = [formatSummary(command)]

        for (idx, section) in command.sections.enumerated() {
            output.append(contentsOf: [
                "\n\(config.indent)[\(idx)] ",
                "addr: \(String(hex: section.addr))-\(String(hex: section.addr + section.size))",
                config.indent,
                section.sectname.padding(config.sectionNameWidth),
                "align: 2^\(section.align) (\(1 << section.align))",
                config.fieldSeparator,
                "flags: \(String.flags(section.flags))",
                config.fieldSeparator,
                "offset: \(section.offset)",
            ])
        }

        return output.joined()
    }

    // MARK: - Source Version Command

    func formatSummary(_ command: SourceVersionCommand) -> String {
        format(command.asLoadCommand())
            + "\(command.version.A).\(command.version.B).\(command.version.C).\(command.version.D).\(command.version.E)"
    }

    // MARK: - Symtab Command

    func formatSummary(_ command: SymtabCommand) -> String {
        [
            format(command.asLoadCommand()),
            "symoff: \(command.symoff)",
            config.fieldSeparator,
            "nsyms: \(command.nsyms)",
            config.fieldSeparator,
            "stroff: \(String(hex: command.stroff))(\(command.stroff))",
            config.fieldSeparator,
            "strsize: \(command.strsize)",
        ].joined()
    }

    // MARK: - Thread Command

    func formatSummary(_ command: ThreadCommand) -> String {
        format(command.asLoadCommand())
    }

    // MARK: - UUID Command

    func formatSummary(_ command: UUIDCommand) -> String {
        format(command.asLoadCommand()) + command.uuid.uuidString
    }

    // MARK: - Dyld Info Command

    func formatSummary(_ command: DyldInfoCommand) -> String {
        format(command.asLoadCommand())
    }

    func formatDetailed(_ command: DyldInfoCommand) -> String {
        [
            format(command.asLoadCommand()), "\n",
            "\(config.indent)rebase: ".padding(config.labelWidth),
            "\(String(hex: command.rebase_off))-\(String(hex: command.rebase_off + command.rebase_size))",
            " (size: \(command.rebase_size))",
            "\n",
            "\(config.indent)bind: ".padding(config.labelWidth),
            "\(String(hex: command.bind_off))-\(String(hex: command.bind_off + command.bind_size))",
            " (size: \(command.bind_size))",
            "\n",
            "\(config.indent)weak_bind: ".padding(config.labelWidth),
            "\(String(hex: command.weak_bind_off))-\(String(hex: command.weak_bind_off + command.weak_bind_size))",
            " (size: \(command.weak_bind_size))",
            "\n",
            "\(config.indent)lazy_bind: ".padding(config.labelWidth),
            "\(String(hex: command.lazy_bind_off))-\(String(hex: command.lazy_bind_off + command.lazy_bind_size))",
            " (size: \(command.lazy_bind_size))",
            "\n",
            "\(config.indent)export: ".padding(config.labelWidth),
            "\(String(hex: command.export_off))-\(String(hex: command.export_off + command.export_size))",
            " (size: \(command.export_size))",
        ].joined()
    }

    // MARK: - Dyld Chained Fixups

    func format(_ report: DyldChainedFixupsReport) -> String {
        var output = format(report.header) + "\n"

        for seg in report.segmentInfo {
            output += "\n" + format(seg)
        }

        output += "\n\nIMPORTS:"
        for (idx, imp) in report.imports.enumerated() {
            output += "\n\(config.fieldSeparator)[\(idx)]".padding(6) + format(imp)
        }

        return output
    }

    func format(_ header: DyldChainedFixupsHeader) -> String {
        [
            "CHAINED_FIXUPS_HEADER".padding(25),
            "starts_offset: \(header.startsOffset)",
            config.fieldSeparator,
            "imports_offset: \(header.importsOffset)",
            config.fieldSeparator,
            "imports_count: \(header.importsCount)",
            config.fieldSeparator,
            "symbols_offset: \(header.symbolsOffset)",
            "\n".padding(26),
            "imports_format: \(header.importsFormat.readableValue ?? String(header.importsFormat.rawValue))",
            config.fieldSeparator,
            "symbols_format: \(header.symbolsFormat.readableValue ?? String(header.symbolsFormat.rawValue))",
        ].joined()
    }

    func format(_ chainedImport: DyldChainedImport) -> String {
        var output = [
            "lib_ordinal: ",
            "\(chainedImport.libOrdinal)".padding(6),
            "weak_import: ",
            "\(chainedImport.isWeakImport)".padding(8),
            "name_offset: ",
            "\(chainedImport.nameOffset)".padding(8),
        ]

        if let dylib = chainedImport.dylibName, let symbol = chainedImport.symbolName {
            output.append("(\(dylib), \(symbol))")
        }

        return output.joined()
    }

    func format(_ segmentInfo: DyldChainedSegmentInfo) -> String {
        var output = ["SEGMENT \(segmentInfo.segmentName) (offset: \(segmentInfo.segInfoOffset))"]

        if let startsInSegment = segmentInfo.startsInSegment {
            output.append("\n")
            output.append(formatSummary(startsInSegment))
            output.append("\n")
            output.append(formatDetailed(startsInSegment))
        }

        return output.joined()
    }

    func formatSummary(_ startsInSegment: DyldChainedSegmentInfo.StartsInSegment) -> String {
        [
            "\(config.fieldSeparator)size: \(startsInSegment.size)",
            "\(config.fieldSeparator)page_size: \(startsInSegment.pageSize)",
            "\(config.fieldSeparator)pointer_format: \(startsInSegment.pointerFormat.readableValue ?? String(startsInSegment.pointerFormat.rawValue))",
            "\(config.fieldSeparator)segment_offset: \(startsInSegment.segmentOffset)",
            "\(config.fieldSeparator)max_valid_pointer: \(startsInSegment.maxValidPointer)",
            "\(config.fieldSeparator)page_count: \(startsInSegment.pageCount)",
            "\(config.fieldSeparator)page_start: \(startsInSegment.pageStart.first ?? 0)",
        ].joined(separator: "\n")
    }

    func formatDetailed(_ startsInSegment: DyldChainedSegmentInfo.StartsInSegment) -> String {
        formatSummary(startsInSegment)
    }

    func format(_ pages: DyldChainedSegmentInfo.Pages) -> String {
        var output = [String]()
        for page in pages.pages {
            output.append("\n" + format(page))
        }
        return output.joined()
    }

    func format(_ pageInfo: DyldChainedSegmentInfo.PageInfo) -> String {
        var output = ["PAGE \(pageInfo.idx) (offset: \(pageInfo.offset))"]

        for element in pageInfo.bindOrRebase {
            output.append("\n" + format(element))
        }

        return output.joined()
    }

    func format(_ bindOrRebase: DyldChainedPtrBindOrRebase) -> String {
        switch bindOrRebase.underlyingValue {
        case .bind32(let bind):
            return format(bind)
        case .bind64(let bind):
            return format(bind)
        case .rebase32(let rebase):
            return format(rebase)
        case .rebase64(let rebase):
            return format(rebase)
        }
    }

    func format(_ bind: DyldChainedPtr64Bind) -> String {
        [
            "BIND",
            config.fieldSeparator,
            "ordinal: \(bind.ordinal)",
            config.fieldSeparator,
            "addend: \(bind.addend)",
        ].joined()
    }

    func format(_ bind: DyldChainedPtr32Bind) -> String {
        [
            "BIND",
            config.fieldSeparator,
            "ordinal: \(bind.ordinal)",
            config.fieldSeparator,
            "addend: \(bind.addend)",
        ].joined()
    }

    func format(_ rebase: DyldChainedPtr64Rebase) -> String {
        [
            "REBASE",
            config.fieldSeparator,
            "target: \(rebase.target)",
            config.fieldSeparator,
            "high8: \(rebase.high8)",
        ].joined()
    }

    func format(_ rebase: DyldChainedPtr32Rebase) -> String {
        [
            "REBASE",
            config.fieldSeparator,
            "target: \(rebase.target)",
        ].joined()
    }

    // MARK: - Helper Formatters

    func formatCmd(_ cmd: Cmd) -> String {
        cmd.readableValue ?? .cmd(cmd.rawValue)
    }

    func formatCPUType(_ cputype: CPUType) -> String {
        cputype.readableValue ?? String(cputype.rawValue)
    }

    func formatFileType(_ filetype: FileType) -> String {
        filetype.readableValue ?? .filetype(filetype.rawValue)
    }

    func formatMagic(_ magic: Magic) -> String {
        if let readableValue = magic.readableValue {
            return "\(readableValue) (\(String.magic(magic.rawValue)))"
        }
        return .magic(magic.rawValue)
    }

    func formatPlatform(_ platform: Platform) -> String {
        platform.readableValue ?? String(platform.rawValue)
    }

    func formatFlags(_ flags: MachOHeader.Flags) -> String {
        flags.readableValue ?? .flags(flags.rawValue)
    }

    // MARK: - Fallback

    func formatUnknown(_ value: Any) -> String {
        "<unable-to-format:\(type(of: value))>"
    }
}
