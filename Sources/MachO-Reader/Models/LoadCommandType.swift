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
        if loadCommand.isOfType(LC_BUILD_VERSION) {
            self = BuildVersionCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_SEGMENT, LC_SEGMENT_64) {
            self = SegmentCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_UUID) {
            self = UUIDCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_SYMTAB) {
            self = SymtabCommand.build(from: loadCommand)
            return
        }
        // swiftlint:disable:next line_length
        if loadCommand.isOfType(LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO, LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_DYLIB_CODE_SIGN_DRS, LC_LINKER_OPTIMIZATION_HINT) || loadCommand.isOfType(LC_DYLD_EXPORTS_TRIE, LC_DYLD_CHAINED_FIXUPS) {
            self = LinkedItDataCommand.build(from: loadCommand)
            return
        }
        // swiftlint:disable:next line_length
        if loadCommand.isOfType(LC_ID_DYLIB, LC_LOAD_DYLIB) || loadCommand.isOfType(LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB) {
            self = DylibCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_ID_DYLINKER, LC_LOAD_DYLINKER, LC_DYLD_ENVIRONMENT) {
            self = DylinkerCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_DYSYMTAB) {
            self = DysymtabCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_SOURCE_VERSION) {
            self = SourceVersionCommand.build(from: loadCommand)
            return
        }
        if loadCommand.isOfType(LC_MAIN) {
            self = EntryPointCommand.build(from: loadCommand)
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
        types.map(Int.init).contains(Int(self.cmd))
    }

    func isOfType(_ types: UInt32...) -> Bool {
        types.contains(self.cmd)
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
