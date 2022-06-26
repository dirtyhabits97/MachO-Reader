import Foundation

public final class DyldChainedFixupsReport {

    // MARK: - Properties

    let file: MachOFile
    /// The pointer to __LINKED it segment where the LC_DYLD_CHAINED_FIXUPS payload lives.
    let fixupData: Data

    public let header: DyldChainedFixupsHeader
    let startsInImage: dyld_chained_starts_in_image

    public private(set) var imports: [DyldChainedImport] = []
    public private(set) var segmentInfo: [DyldChainedSegmentInfo] = []

    // MARK: - Lifecycle

    init(file: MachOFile) {
        guard let dyldChainedFixups = file.commands.getDyldChainedFixups() else {
            fatalError("Expected a DyldChainedFixups command in the macho file.")
        }
        fixupData = file.base.advanced(by: Int(dyldChainedFixups.dataoff))
        self.file = file
        // header of the LC_DYLD_CHAINED_FIXUPS payload
        header = DyldChainedFixupsHeader(fixupData.extract(dyld_chained_fixups_header.self))
        // each of these comes with a segment offset.
        // in that offset information bind / rebase exist
        // as well as imports
        startsInImage = fixupData
            .advanced(by: Int(header.startsOffset))
            .extract(dyld_chained_starts_in_image.self)

        imports = DyldChainedImportBuilder(self).imports
        segmentInfo = DyldChainedStartsInSegmentBuilder(self).segmentInfo
    }

    // MARK: - Methods

    public func pageInfo() -> [DyldChainedSegmentInfo.Pages] {
        DyldChainedSegmentPageInfoBuilder(self).pageInfo
    }
}
