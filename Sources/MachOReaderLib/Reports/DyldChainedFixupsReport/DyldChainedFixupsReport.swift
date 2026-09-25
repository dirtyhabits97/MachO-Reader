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

    init(file: MachOFile) throws {
        guard let dyldChainedFixups = try file.commands.getDyldChainedFixups() else {
            throw MachOFileError.missingDyldChainedFixups
        }
        fixupData = file.base.advanced(by: Int(dyldChainedFixups.dataoff))
        self.file = file
        // header of the LC_DYLD_CHAINED_FIXUPS payload
        header = try DyldChainedFixupsHeader(fixupData.decode(dyld_chained_fixups_header.self))
        // each of these comes with a segment offset.
        // in that offset information bind / rebase exist
        // as well as imports
        startsInImage = try BinaryDecoder(data: fixupData)
            .decode(dyld_chained_starts_in_image.self, at: Int(header.startsOffset))

        imports = try DyldChainedImportBuilder(self).imports
        segmentInfo = try DyldChainedStartsInSegmentBuilder(self).segmentInfo
    }

    // MARK: - Methods

    public func pageInfo() throws -> [DyldChainedSegmentInfo.Pages] {
        try DyldChainedSegmentPageInfoBuilder(self).pageInfo
    }
}
