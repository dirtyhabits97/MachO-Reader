import Foundation

// TODO: remove prints
public final class DyldChainedFixupsReport {

    // MARK: - Properties

    let file: MachOFile
    /// The pointer to __LINKED it segment where the LC_DYLD_CHAINED_FIXUPS payload lives.
    let fixupData: Data

    let header: dyld_chained_fixups_header
    let startsInImage: dyld_chained_starts_in_image

    public private(set) var imports: [DyldChainedImport] = []
    public private(set) var segmentInfo: [DyldChainedSegmentInfo] = []

    // MARK: - Lifecycle

    init(file: MachOFile) {
        // TODO: this should throw
        guard let dyldChainedFixups = file.commands.getDyldChainedFixups() else {
            fatalError("Expected a DyldChainedFixups command in the macho file.")
        }
        fixupData = file.base.advanced(by: Int(dyldChainedFixups.dataoff))
        self.file = file
        // header of the LC_DYLD_CHAINED_FIXUPS payload
        header = fixupData.extract(dyld_chained_fixups_header.self)
        // each of these comes with a segment offset.
        // in that offset information bind / rebase exist
        // as well as imports
        startsInImage = fixupData
            .advanced(by: Int(header.startsOffset))
            .extract(dyld_chained_starts_in_image.self)

        // build the imports first, since we use them when building the segments
        imports = DyldChainedImportBuilder(self).imports
        segmentInfo = DyldChainedStartsInSegmentBuilder(self).segmentInfo
    }

    // MARK: - Methods

    public func pageInfo() -> [DyldChainedSegmentInfo.Pages] {
        DyldChainedSegmentPageInfoBuilder(self).pageInfo
    }
}

// TODO: move this somewhere
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
