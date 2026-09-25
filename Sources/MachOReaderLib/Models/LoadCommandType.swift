import Foundation

public enum LoadCommandType {

    case buildVersionCommand(BuildVersionCommand)
    case dyldInfoCommand(DyldInfoCommand)
    case dylibCommand(DylibCommand)
    case dylinkerCommand(DylinkerCommand)
    case dysymtabCommand(DysymtabCommand)
    case entryPointCommand(EntryPointCommand)
    case linkedItDataCommand(LinkedItDataCommand)
    case segmentCommand(SegmentCommand)
    case sourceVersionCommand(SourceVersionCommand)
    case symtabCommand(SymtabCommand)
    case threadCommand(ThreadCommand)
    case uuidCommand(UUIDCommand)

    case unspecified(LoadCommand)

    // swiftlint:disable:next cyclomatic_complexity
    init(from loadCommand: LoadCommand) throws {
        switch loadCommand.cmd {
        case .buildVersion:
            self = try .buildVersionCommand(BuildVersionCommand(from: loadCommand))
        case .dyldInfo, .dyldInfoOnly:
            self = try .dyldInfoCommand(DyldInfoCommand(from: loadCommand))
        case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib:
            self = try .dylibCommand(DylibCommand(from: loadCommand))
        case .idDylinker, .loadDylinker, .dyldEnvironment:
            self = try .dylinkerCommand(DylinkerCommand(from: loadCommand))
        case .dysymtab:
            self = try .dysymtabCommand(DysymtabCommand(from: loadCommand))
        case .main:
            self = try .entryPointCommand(EntryPointCommand(from: loadCommand))
        case .codeSignature, .segmentSplitInfo, .functionStarts, .dataInCode,
             .dylibCodeSignDrs, .linkerOptimizationHint, .dyldExportsTrie, .dyldChainedFixups:
            self = try .linkedItDataCommand(LinkedItDataCommand(from: loadCommand))
        case .segment, .segment64:
            self = try .segmentCommand(SegmentCommand(from: loadCommand))
        case .sourceVersion:
            self = try .sourceVersionCommand(SourceVersionCommand(from: loadCommand))
        case .symtab:
            self = try .symtabCommand(SymtabCommand(from: loadCommand))
        case .thread, .unixthread:
            self = try .threadCommand(ThreadCommand(from: loadCommand))
        case .uuid:
            self = try .uuidCommand(UUIDCommand(from: loadCommand))
        default:
            self = .unspecified(loadCommand)
        }
    }
}
