import Foundation
import MachO

/// Errors that can occur when parsing a Mach-O file.
public enum MachOFileError: Error, CustomStringConvertible {

    /// The file does not have a valid Mach-O magic number.
    case invalidMagic(UInt32)

    public var description: String {
        switch self {
        case .invalidMagic(let value):
            return "Invalid Mach-O magic: 0x\(String(value, radix: 16)). The file is not a valid Mach-O binary."
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

    init(from data: Data, arch: String?) throws {
        // Validate magic before attempting to parse
        let magic = Magic(peek: data)
        guard magic.isValid else {
            throw MachOFileError.invalidMagic(magic.rawValue)
        }

        fatHeader = MachOFatHeader(from: data)

        var data = data
        if let offset = fatHeader?.offset(for: CPUType(from: arch)) {
            data = data.advanced(by: Int(offset))
        }

        base = data

        header = MachOHeader(from: data)

        var commands = [LoadCommand]()
        var offset = header.size

        for _ in 0 ..< header.ncmds {
            let data = data.advanced(by: offset)
            let loadCommand = LoadCommand(from: data, isSwapped: header.magic.isSwapped)
            commands.append(loadCommand)
            offset += Int(loadCommand.cmdsize)
        }

        self.commands = commands
    }

    // MARK: - Reports

    public func dyldChainedFixupsReport() -> DyldChainedFixupsReport {
        DyldChainedFixupsReport(file: self)
    }
}
