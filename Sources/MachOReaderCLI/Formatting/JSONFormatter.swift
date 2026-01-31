// swiftlint:disable file_length type_body_length
import Foundation
import MachOReaderLib

/// Formats Mach-O data structures as JSON dictionaries
final class JSONFormatter {

    // MARK: - Properties

    private let includeRawValues: Bool

    // MARK: - Lifecycle

    init(includeRawValues: Bool = false) {
        self.includeRawValues = includeRawValues
    }

    // MARK: - Output Helpers

    func toJSONString(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        ), let string = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"<unable-to-serialize>\"}"
        }
        return string
    }

    func toJSONString(_ array: [[String: Any]]) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: array,
            options: [.prettyPrinted, .sortedKeys]
        ), let string = String(data: data, encoding: .utf8) else {
            return "[{\"error\": \"<unable-to-serialize>\"}]"
        }
        return string
    }

    // MARK: - MachOFile

    func format(_ file: MachOFile) -> [String: Any] {
        var result: [String: Any] = [
            "header": format(file.header),
            "loadCommands": file.commands.map { format($0.commandType()) },
        ]

        if let fatHeader = file.fatHeader {
            result["fatHeader"] = format(fatHeader)
        }

        return result
    }

    // MARK: - Fat Header

    func format(_ fatHeader: MachOFatHeader) -> [String: Any] {
        var result: [String: Any] = [
            "type": "FAT_HEADER",
            "magic": formatMagic(fatHeader.magic),
            "nfat_archs": fatHeader.archs.count,
            "architectures": fatHeader.archs.map { format($0) },
        ]

        if includeRawValues {
            result["magic_raw"] = fatHeader.magic.rawValue
        }

        return result
    }

    func format(_ arch: MachOFatHeader.Architecture) -> [String: Any] {
        var result: [String: Any] = [
            "cputype": formatCPUType(arch.cputype),
            "cpusubtype": arch.cpuSubtype.rawValue,
            "offset": arch.offset,
            "size": arch.size,
            "align": arch.align,
        ]

        if let readableCpuSubType = arch.cpuSubtype.readableValue(cpuType: arch.cputype) {
            result["cpusubtype_name"] = readableCpuSubType
        }

        if includeRawValues {
            result["cputype_raw"] = arch.cputype.rawValue
        }

        return result
    }

    // MARK: - Mach-O Header

    func format(_ header: MachOHeader) -> [String: Any] {
        var result: [String: Any] = [
            "type": "MACH_HEADER",
            "cputype": formatCPUType(header.cputype),
            "filetype": formatFileType(header.filetype),
            "ncmds": header.ncmds,
            "sizeofcmds": header.sizeofcmds,
            "flags": formatFlags(header.flags),
        ]

        if includeRawValues {
            result["cputype_raw"] = header.cputype.rawValue
            result["filetype_raw"] = header.filetype.rawValue
            result["flags_raw"] = header.flags.rawValue
        }

        return result
    }

    // MARK: - Load Commands

    func format(_ command: LoadCommand) -> [String: Any] {
        var result: [String: Any] = [
            "cmd": formatCmd(command.cmd),
            "cmdsize": command.cmdsize,
        ]

        if includeRawValues {
            result["cmd_raw"] = command.cmd.rawValue
        }

        return result
    }

    // swiftlint:disable:next cyclomatic_complexity
    func format(_ commandType: LoadCommandType) -> [String: Any] {
        switch commandType {
        case let .buildVersionCommand(cmd):
            return format(cmd)
        case let .dyldInfoCommand(cmd):
            return format(cmd)
        case let .dylibCommand(cmd):
            return format(cmd)
        case let .dylinkerCommand(cmd):
            return format(cmd)
        case let .dysymtabCommand(cmd):
            return format(cmd)
        case let .entryPointCommand(cmd):
            return format(cmd)
        case let .linkedItDataCommand(cmd):
            return format(cmd)
        case let .segmentCommand(cmd):
            return format(cmd)
        case let .sourceVersionCommand(cmd):
            return format(cmd)
        case let .symtabCommand(cmd):
            return format(cmd)
        case let .threadCommand(cmd):
            return format(cmd)
        case let .uuidCommand(cmd):
            return format(cmd)
        case let .unspecified(cmd):
            return format(cmd)
        }
    }

    // MARK: - Build Version Command

    func format(_ command: BuildVersionCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["platform"] = formatPlatform(command.platform)
        result["minos"] = "\(command.minOS)"
        result["sdk"] = "\(command.sdk)"
        result["ntools"] = command.ntools
        result["tools"] = command.buildToolVersions.map { tool -> [String: Any] in
            [
                "tool": tool.tool.readableValue ?? String(tool.tool.rawValue),
                "version": "\(tool.version)",
            ]
        }

        if includeRawValues {
            result["platform_raw"] = command.platform.rawValue
        }

        return result
    }

    // MARK: - Dylib Command

    func format(_ command: DylibCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["name"] = command.dylib.name
        result["timestamp"] = ISO8601DateFormatter().string(from: command.dylib.timestamp)
        result["current_version"] = "\(command.dylib.currentVersion)"
        result["compatibility_version"] = "\(command.dylib.compatibilityVersion)"

        return result
    }

    // MARK: - Dylinker Command

    func format(_ command: DylinkerCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())
        result["name"] = command.name
        return result
    }

    // MARK: - Dysymtab Command

    func format(_ command: DysymtabCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["ilocalsym"] = command.ilocalsym
        result["nlocalsym"] = command.nlocalsym
        result["iextdefsym"] = command.iextdefsym
        result["nextdefsym"] = command.nextdefsym
        result["iundefsym"] = command.iundefsym
        result["nundefsym"] = command.nundefsym
        result["tocoff"] = command.tocoff
        result["ntoc"] = command.ntoc
        result["modtaboff"] = command.modtaboff
        result["nmodtab"] = command.nmodtab
        result["extrefsymoff"] = command.extrefsymoff
        result["nextrefsyms"] = command.nextrefsyms
        result["indirectsymoff"] = command.indirectsymoff
        result["nindirectsyms"] = command.nindirectsyms
        result["extreloff"] = command.extreloff
        result["nextrel"] = command.nextrel
        result["locreloff"] = command.locreloff
        result["nlocrel"] = command.nlocrel

        return result
    }

    // MARK: - Entry Point Command

    func format(_ command: EntryPointCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["entryoff"] = command.entryoff
        result["entryoff_hex"] = String(hex: command.entryoff)
        result["stacksize"] = command.stacksize

        return result
    }

    // MARK: - Linked It Data Command

    func format(_ command: LinkedItDataCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["dataoff"] = command.dataoff
        result["dataoff_hex"] = String(hex: command.dataoff)
        result["datasize"] = command.datasize

        return result
    }

    // MARK: - Segment Command

    func format(_ command: SegmentCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["segname"] = command.segname
        result["vmaddr"] = command.vmaddr
        result["vmaddr_hex"] = String(hex: command.vmaddr)
        result["vmsize"] = command.vmsize
        result["fileoff"] = command.fileoff
        result["fileoff_hex"] = String(hex: command.fileoff)
        result["filesize"] = command.filesize
        result["maxprot"] = command.maxprot
        result["initprot"] = command.initprot
        result["nsects"] = command.nsects
        result["flags"] = command.flags
        result["sections"] = command.sections.map { format($0) }

        return result
    }

    func format(_ section: SegmentCommand.Section) -> [String: Any] {
        [
            "sectname": section.sectname,
            "segname": section.segname,
            "addr": section.addr,
            "addr_hex": String(hex: section.addr),
            "size": section.size,
            "offset": section.offset,
            "align": section.align,
            "reloff": section.reloff,
            "nreloc": section.nreloc,
            "flags": section.flags,
            "flags_hex": String.flags(section.flags),
        ]
    }

    // MARK: - Source Version Command

    func format(_ command: SourceVersionCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())
        let ver = command.version
        result["version"] = "\(ver.A).\(ver.B).\(ver.C).\(ver.D).\(ver.E)"
        return result
    }

    // MARK: - Symtab Command

    func format(_ command: SymtabCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["symoff"] = command.symoff
        result["nsyms"] = command.nsyms
        result["stroff"] = command.stroff
        result["stroff_hex"] = String(hex: command.stroff)
        result["strsize"] = command.strsize

        return result
    }

    // MARK: - Thread Command

    func format(_ command: ThreadCommand) -> [String: Any] {
        format(command.asLoadCommand())
    }

    // MARK: - UUID Command

    func format(_ command: UUIDCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())
        result["uuid"] = command.uuid.uuidString
        return result
    }

    // MARK: - Dyld Info Command

    func format(_ command: DyldInfoCommand) -> [String: Any] {
        var result = format(command.asLoadCommand())

        result["rebase_off"] = command.rebase_off
        result["rebase_size"] = command.rebase_size
        result["bind_off"] = command.bind_off
        result["bind_size"] = command.bind_size
        result["weak_bind_off"] = command.weak_bind_off
        result["weak_bind_size"] = command.weak_bind_size
        result["lazy_bind_off"] = command.lazy_bind_off
        result["lazy_bind_size"] = command.lazy_bind_size
        result["export_off"] = command.export_off
        result["export_size"] = command.export_size

        return result
    }

    // MARK: - Dyld Chained Fixups

    func format(_ report: DyldChainedFixupsReport) -> [String: Any] {
        [
            "header": format(report.header),
            "segments": report.segmentInfo.map { format($0) },
            "imports": report.imports.enumerated().map { idx, imp in
                var result = format(imp)
                result["index"] = idx
                return result
            },
        ]
    }

    func format(_ header: DyldChainedFixupsHeader) -> [String: Any] {
        [
            "type": "CHAINED_FIXUPS_HEADER",
            "fixups_version": header.fixupsVersion,
            "starts_offset": header.startsOffset,
            "imports_offset": header.importsOffset,
            "symbols_offset": header.symbolsOffset,
            "imports_count": header.importsCount,
            "imports_format": header.importsFormat.readableValue ?? String(header.importsFormat.rawValue),
            "symbols_format": header.symbolsFormat.readableValue ?? String(header.symbolsFormat.rawValue),
        ]
    }

    func format(_ chainedImport: DyldChainedImport) -> [String: Any] {
        var result: [String: Any] = [
            "lib_ordinal": chainedImport.libOrdinal,
            "weak_import": chainedImport.isWeakImport,
            "name_offset": chainedImport.nameOffset,
        ]

        if let dylib = chainedImport.dylibName {
            result["dylib_name"] = dylib
        }

        if let symbol = chainedImport.symbolName {
            result["symbol_name"] = symbol
        }

        return result
    }

    func format(_ segmentInfo: DyldChainedSegmentInfo) -> [String: Any] {
        var result: [String: Any] = [
            "segment_name": segmentInfo.segmentName,
            "seg_info_offset": segmentInfo.segInfoOffset,
        ]

        if let startsInSegment = segmentInfo.startsInSegment {
            result["starts_in_segment"] = format(startsInSegment)
        }

        return result
    }

    func format(_ startsInSegment: DyldChainedSegmentInfo.StartsInSegment) -> [String: Any] {
        let pointerFormat = startsInSegment.pointerFormat
        return [
            "size": startsInSegment.size,
            "page_size": startsInSegment.pageSize,
            "pointer_format": pointerFormat.readableValue ?? String(pointerFormat.rawValue),
            "segment_offset": startsInSegment.segmentOffset,
            "max_valid_pointer": startsInSegment.maxValidPointer,
            "page_count": startsInSegment.pageCount,
            "page_starts": startsInSegment.pageStart,
        ]
    }

    func format(_ pages: DyldChainedSegmentInfo.Pages) -> [[String: Any]] {
        pages.pages.map { format($0) }
    }

    func format(_ pageInfo: DyldChainedSegmentInfo.PageInfo) -> [String: Any] {
        [
            "index": pageInfo.idx,
            "offset": pageInfo.offset,
            "bind_or_rebase": pageInfo.bindOrRebase.map { format($0) },
        ]
    }

    func format(_ bindOrRebase: DyldChainedPtrBindOrRebase) -> [String: Any] {
        switch bindOrRebase.underlyingValue {
        case let .bind32(bind):
            return format(bind)
        case let .bind64(bind):
            return format(bind)
        case let .rebase32(rebase):
            return format(rebase)
        case let .rebase64(rebase):
            return format(rebase)
        }
    }

    func format(_ bind: DyldChainedPtr64Bind) -> [String: Any] {
        [
            "type": "BIND",
            "bits": 64,
            "ordinal": bind.ordinal,
            "addend": bind.addend,
        ]
    }

    func format(_ bind: DyldChainedPtr32Bind) -> [String: Any] {
        [
            "type": "BIND",
            "bits": 32,
            "ordinal": bind.ordinal,
            "addend": bind.addend,
        ]
    }

    func format(_ rebase: DyldChainedPtr64Rebase) -> [String: Any] {
        [
            "type": "REBASE",
            "bits": 64,
            "target": rebase.target,
            "high8": rebase.high8,
        ]
    }

    func format(_ rebase: DyldChainedPtr32Rebase) -> [String: Any] {
        [
            "type": "REBASE",
            "bits": 32,
            "target": rebase.target,
        ]
    }

    // MARK: - Helper Formatters

    func formatCmd(_ cmd: Cmd) -> String {
        cmd.readableValue ?? "0x\(String(cmd.rawValue, radix: 16))"
    }

    func formatCPUType(_ cputype: CPUType) -> String {
        cputype.readableValue ?? String(cputype.rawValue)
    }

    func formatFileType(_ filetype: FileType) -> String {
        filetype.readableValue ?? "0x\(String(filetype.rawValue, radix: 16))"
    }

    func formatMagic(_ magic: Magic) -> String {
        magic.readableValue ?? "0x\(String(magic.rawValue, radix: 16))"
    }

    func formatPlatform(_ platform: Platform) -> String {
        platform.readableValue ?? String(platform.rawValue)
    }

    func formatFlags(_ flags: MachOHeader.Flags) -> String {
        flags.readableValue ?? "0x\(String(flags.rawValue, radix: 16))"
    }

    // MARK: - Fallback

    func formatUnknown(_ value: Any) -> [String: Any] {
        ["error": "<unable-to-format>", "type": "\(type(of: value))"]
    }
}

// swiftlint:enable file_length type_body_length
