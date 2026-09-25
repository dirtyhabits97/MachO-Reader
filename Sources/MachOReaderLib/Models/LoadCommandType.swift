import Foundation

public enum LoadCommandType {

    case buildVersionCommand(BuildVersionCommand)
    case dyldInfoCommand(DyldInfoCommand)
    case dylibCommand(DylibCommand)
    case dylinkerCommand(DylinkerCommand)
    case dysymtabCommand(DysymtabCommand)
    case entryPointCommand(EntryPointCommand)
    case linkedItDataCommand(LinkedItDataCommand)
    case rpathCommand(RpathCommand)
    case segmentCommand(SegmentCommand)
    case sourceVersionCommand(SourceVersionCommand)
    case symtabCommand(SymtabCommand)
    case threadCommand(ThreadCommand)
    case uuidCommand(UUIDCommand)
    case versionMinCommand(VersionMinCommand)

    case unspecified(LoadCommand)

    init(from loadCommand: LoadCommand) {
        let commandTypes: [LoadCommandTypeRepresentable.Type] = [
            BuildVersionCommand.self,
            DyldInfoCommand.self,
            DylibCommand.self,
            DylinkerCommand.self,
            DysymtabCommand.self,
            EntryPointCommand.self,
            LinkedItDataCommand.self,
            RpathCommand.self,
            SegmentCommand.self,
            SourceVersionCommand.self,
            SymtabCommand.self,
            ThreadCommand.self,
            UUIDCommand.self,
            VersionMinCommand.self,
        ]

        for commandType in commandTypes where loadCommand.is(commandType) {
            self = commandType.build(from: loadCommand)
            return
        }

        self = .unspecified(loadCommand)
    }
}
