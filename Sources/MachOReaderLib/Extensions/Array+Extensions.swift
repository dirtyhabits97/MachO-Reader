import Foundation

public extension [LoadCommand] {

    func getDyldChainedFixups() throws -> LinkedItDataCommand? {
        for loadCommand in self where loadCommand.cmd == .dyldChainedFixups {
            guard case let .linkedItDataCommand(linkedItDataCommand) = try loadCommand.commandType() else { continue }
            return linkedItDataCommand
        }
        return nil
    }

    func getSymtabCommand() throws -> SymtabCommand? {
        for loadCommand in self where loadCommand.cmd == .symtab {
            guard case let .symtabCommand(symtabCommand) = try loadCommand.commandType() else { continue }
            return symtabCommand
        }
        return nil
    }

    func getDyldExportsTrie() throws -> LinkedItDataCommand? {
        for loadCommand in self where loadCommand.cmd == .dyldExportsTrie {
            guard case let .linkedItDataCommand(linkedItDataCommand) = try loadCommand.commandType() else { continue }
            return linkedItDataCommand
        }
        return nil
    }

    func getDyldInfoCommand() throws -> DyldInfoCommand? {
        for loadCommand in self where loadCommand.cmd == .dyldInfo || loadCommand.cmd == .dyldInfoOnly {
            guard case let .dyldInfoCommand(dyldInfoCommand) = try loadCommand.commandType() else { continue }
            return dyldInfoCommand
        }
        return nil
    }

    func getBuildVersionCommand() throws -> BuildVersionCommand? {
        for loadCommand in self where loadCommand.cmd == .buildVersion {
            guard case let .buildVersionCommand(buildVersionCommand) = try loadCommand.commandType() else { continue }
            return buildVersionCommand
        }
        return nil
    }

    func getDylibCommands() throws -> [DylibCommand] {
        try compactMap { loadCommand -> DylibCommand? in
            guard case let .dylibCommand(dylibCommand) = try loadCommand.commandType() else { return nil }
            return dylibCommand
        }
    }

    func getSegmentCommands() throws -> [SegmentCommand] {
        try compactMap { loadCommand -> SegmentCommand? in
            guard case let .segmentCommand(segmentCommand) = try loadCommand.commandType() else { return nil }
            return segmentCommand
        }
    }

    func getLoadCommands(_ name: String) -> [LoadCommand] {
        filter { $0.cmd.readableValue == name }
    }
}
