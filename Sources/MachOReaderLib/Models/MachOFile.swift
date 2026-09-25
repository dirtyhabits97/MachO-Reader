import Foundation
import MachO

/// Errors that can occur when parsing a Mach-O file.
public enum MachOFileError: Error, Equatable, CustomStringConvertible {

    /// The file does not have a valid Mach-O magic number.
    case invalidMagic(UInt32)

    /// The file does not contain an `LC_DYLD_CHAINED_FIXUPS` load command.
    case missingDyldChainedFixups

    /// The file does not contain an `LC_SYMTAB` load command.
    case missingSymbolTable

    /// The file is too short to contain data expected at the given offset.
    case truncated(offset: Int, size: Int)

    /// A load command's `cmdsize` is smaller than a `load_command` header.
    case invalidLoadCommandSize(cmdsize: UInt32, minimum: Int)

    /// The given `--arch` string is not a recognized CPU type.
    case unknownArch(String)

    /// The requested architecture has no matching slice in this binary.
    case archNotFound(CPUType)
    /// The file does not contain an `LC_DYLD_EXPORTS_TRIE` load command, nor an
    /// `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` load command with an export blob.
    case missingExportTrie
    /// The file does not contain an `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` load command.
    case missingDyldInfo

    public var description: String {
        switch self {
        case let .invalidMagic(value):
            "Invalid Mach-O magic: 0x\(String(value, radix: 16)). The file is not a valid Mach-O binary."
        case .missingDyldChainedFixups:
            "This Mach-O binary does not contain an LC_DYLD_CHAINED_FIXUPS load command."
        case .missingSymbolTable:
            "This Mach-O binary does not contain an LC_SYMTAB load command."
        case let .truncated(offset, size):
            "The file is truncated: expected data at offset \(offset), but the file is only \(size) bytes."
        case let .invalidLoadCommandSize(cmdsize, minimum):
            "Invalid load command: cmdsize \(cmdsize) is smaller than the minimum of \(minimum) bytes."
        case let .unknownArch(arch):
            "Unknown architecture \"\(arch)\". Expected one of: x86, x86_64, arm, arm64, arm64e."
        case let .archNotFound(cpuType):
            "This Mach-O binary does not contain a slice for architecture " +
                "\(cpuType.readableValue ?? String(cpuType.rawValue))."
        case .missingExportTrie:
            "This Mach-O binary does not contain an LC_DYLD_EXPORTS_TRIE or LC_DYLD_INFO(_ONLY) load command."
        case .missingDyldInfo:
            "This Mach-O binary does not contain an LC_DYLD_INFO or LC_DYLD_INFO_ONLY load command."
        }
    }
}

public struct MachOFile {

    // MARK: - Properties

    public let fatHeader: MachOFatHeader?
    public let header: MachOHeader
    public private(set) var commands: [LoadCommand]

    /// A pointer to the start of the header of this file in memory.
    private(set) var base: Data

    // MARK: - Lifecycle

    public init(from url: URL, arch: String?) throws {
        try self.init(from: Data(contentsOf: url), arch: arch)
    }

    public init(from data: Data, arch: String?) throws {
        // Validate magic before attempting to parse
        let magic = try Magic(peek: data)
        guard magic.isValid else {
            throw MachOFileError.invalidMagic(magic.rawValue)
        }

        // Resolve the requested arch up front, and reject unknown ones strictly.
        let requestedCPUType = try MachOFile.resolveCPUType(from: arch)

        fatHeader = MachOFatHeader(from: data)
        let sliceData = try MachOFile.slice(data, fatHeader: fatHeader, requestedCPUType: requestedCPUType)
        base = sliceData

        header = try MachOHeader(from: sliceData)

        // A thin binary must match the requested arch exactly, since there is no slice to select.
        if fatHeader == nil, let requestedCPUType, header.cputype != requestedCPUType {
            throw MachOFileError.archNotFound(requestedCPUType)
        }

        commands = try MachOFile.parseLoadCommands(from: sliceData, header: header)
    }

    // MARK: - Private Methods

    /// Resolves an `--arch` string to a `CPUType`, throwing if it isn't recognized.
    private static func resolveCPUType(from arch: String?) throws -> CPUType? {
        guard let arch else { return nil }
        guard let cpuType = CPUType(from: arch) else {
            throw MachOFileError.unknownArch(arch)
        }
        return cpuType
    }

    /// Returns the slice of `data` for the requested arch, or `data` unchanged for a thin binary.
    private static func slice(_ data: Data, fatHeader: MachOFatHeader?, requestedCPUType: CPUType?) throws -> Data {
        guard let fatHeader else { return data }

        let offset: UInt64
        if let requestedCPUType {
            guard let matched = fatHeader.offset(for: requestedCPUType) else {
                throw MachOFileError.archNotFound(requestedCPUType)
            }
            offset = matched
        } else {
            guard let firstOffset = fatHeader.offset(for: nil) else {
                throw MachOFileError.truncated(offset: 0, size: data.count)
            }
            offset = firstOffset
        }

        guard offset <= UInt64(data.count) else {
            throw MachOFileError.truncated(offset: Int(offset), size: data.count)
        }
        return data.advanced(by: Int(offset))
    }

    /// Walks and validates the load commands following `header` in `data`.
    private static func parseLoadCommands(from data: Data, header: MachOHeader) throws -> [LoadCommand] {
        guard header.size <= data.count else {
            throw MachOFileError.truncated(offset: header.size, size: data.count)
        }

        var commands = [LoadCommand]()
        var offset = header.size

        for _ in 0 ..< header.ncmds {
            guard offset + MemoryLayout<load_command>.size <= data.count else {
                throw MachOFileError.truncated(offset: offset, size: data.count)
            }

            let commandData = data.advanced(by: offset)
            let loadCommand = try LoadCommand(from: commandData, isSwapped: header.magic.isSwapped)

            guard loadCommand.cmdsize >= MemoryLayout<load_command>.size else {
                throw MachOFileError.invalidLoadCommandSize(cmdsize: loadCommand.cmdsize,
                                                            minimum: MemoryLayout<load_command>.size)
            }
            guard offset + Int(loadCommand.cmdsize) <= data.count else {
                throw MachOFileError.truncated(offset: offset, size: data.count)
            }

            commands.append(loadCommand)
            offset += Int(loadCommand.cmdsize)
        }

        return commands
    }

    // MARK: - Reports

    public func dyldChainedFixupsReport() throws -> DyldChainedFixupsReport {
        try DyldChainedFixupsReport(file: self)
    }

    public func symbolTableReport() throws -> SymbolTableReport {
        try SymbolTableReport(file: self)
    }

    public func exportTrieReport() throws -> ExportTrieReport {
        try ExportTrieReport(file: self)
    }

    public func dyldInfoReport() throws -> DyldInfoReport {
        try DyldInfoReport(file: self)
    }
}
