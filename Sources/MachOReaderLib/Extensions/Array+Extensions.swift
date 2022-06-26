import Foundation

extension Array where Element == LoadCommand {

    func getDyldChainedFixups() -> LinkedItDataCommand? {
        lazy
            .filter { loadCommand in loadCommand.cmd == .dyldChainedFixups }
            .compactMap { loadCommand -> LinkedItDataCommand? in
                guard case let .linkedItDataCommand(linkedItDataCommand) = loadCommand.commandType() else { return nil }
                return linkedItDataCommand
            }
            .first
    }

    func getDylibCommands() -> [DylibCommand] {
        compactMap { loadCommand -> DylibCommand? in
            guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
            return dylibCommand
        }
    }

    func getSegmentCommands() -> [SegmentCommand] {
        compactMap { loadCommand -> SegmentCommand? in
            guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
            return segmentCommand
        }
    }
}
