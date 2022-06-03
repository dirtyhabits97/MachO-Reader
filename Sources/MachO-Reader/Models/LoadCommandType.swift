import Foundation

enum LoadCommandType {

    case buildVersionCommand(BuildVersionCommand)
    case dylibCommand(DylibCommand)
    case dylinkerCommand(DylinkerCommand)
    case dysymtabCommand(DysymtabCommand)
    case entryPointCommand(EntryPointCommand)
    case linkedItDataCommand(LinkedItDataCommand)
    case segmentCommand(SegmentCommand)
    case sourceVersionCommand(SourceVersionCommand)
    case symtabCommand(SymtabCommand)
    case uuidCommand(UUIDCommand)

    case unspecified

    init(from loadCommand: LoadCommand) {
        if loadCommand.cmd.isBuildVersionCommand {
            self = BuildVersionCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isDylibCommand {
            self = DylibCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isDylinkerCommand {
            self = DylinkerCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isDysymtabCommand {
            self = DysymtabCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isEntryPointCommand {
            self = EntryPointCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isLinkedItDataCommand {
            self = LinkedItDataCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isSegmentCommand {
            self = SegmentCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isSourceVersionCommand {
            self = SourceVersionCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isSymtabCommand {
            self = SymtabCommand.build(from: loadCommand)
            return
        }
        if loadCommand.cmd.isUUIDCommand {
            self = UUIDCommand.build(from: loadCommand)
            return
        }
        self = .unspecified
    }
}

protocol LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType
}

// MARK: - Helpers

private extension LoadCommand {

    func isOfType(_ types: Int32...) -> Bool {
        types.map(Int.init).contains(Int(self.cmd.rawValue))
    }

    func isOfType(_ types: UInt32...) -> Bool {
        types.contains(self.cmd.rawValue)
    }
}

extension LoadCommandType: CustomStringConvertible {

    var description: String {
        switch self {
        case .buildVersionCommand(let command):
            return command.description
        case .dylibCommand(let command):
            return command.description
        case .dylinkerCommand(let command):
            return command.description
        case .dysymtabCommand(let command):
            return command.description
        case .entryPointCommand(let command):
            return command.description
        case .linkedItDataCommand(let command):
            return command.description
        case .segmentCommand(let command):
            return command.description
        case .symtabCommand(let command):
            return command.description
        case .sourceVersionCommand(let command):
            return command.description
        case .uuidCommand(let command):
            return command.description
        case .unspecified:
            return ""
        }
    }
}
