import Foundation

extension [LoadCommand] {

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
}
