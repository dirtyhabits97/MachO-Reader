import Foundation
import MachO

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

    init(from data: Data, arch: String?) {
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
