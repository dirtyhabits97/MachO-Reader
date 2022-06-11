import Foundation
import MachO

struct MachOFile {

    // MARK: - Properties

    let fatHeader: FatHeader?
    let header: MachOHeader
    var commands: [LoadCommand]

    // MARK: - Lifecycle

    init(from url: URL, arch: String?) throws {
        self.init(from: try Data(contentsOf: url), arch: arch)
    }

    init(from data: Data, arch: String?) {
        fatHeader = FatHeader(from: data)

        var data = data
        if let offset = fatHeader?.offset(for: CPUType(from: arch)) {
            data = data.advanced(by: Int(offset))
        }

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
}
