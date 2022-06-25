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

    public func pageInfo() -> [DyldChainedSegmentInfo.Pages] {
        DyldChainedSegmentPageInfoBuilder(self).pageInfo
    }

    // MARK: - Methods

    // TODO: might need to move this to its own struct / class with how many pointerFormat we want to support
    // TODO: Finish implementing this
    private func getPageInfo(using _: dyld_chained_fixups_header, segmentInfo: dyld_chained_starts_in_segment) {
        for idx in 0 ..< Int(segmentInfo.pageCount) {
            print("PAGE: \(idx) (offset: \(segmentInfo.pageStart[idx]))")

            var chainedOffset = UInt32(segmentInfo.segmentOffset)
                + UInt32(segmentInfo.pageSize * 0)
                + UInt32(segmentInfo.pageStart[idx])

            print("0x" + String(format: "%08llx", segmentInfo.segmentOffset), "Chained offset: \(chainedOffset)")

            var done = false
            while !done {
                // TODO: replace this with constants
                // [DYLD_CHAINED_PTR_64, DYLD_CHAINED_PTR_64_OFFSET]
                if [2, 6].contains(segmentInfo.pointerFormat) {

                    let data = file.base.advanced(by: Int(chainedOffset))
                    let bind = data.extract(dyld_chained_ptr_64_bind.self)

                    if bind.bind {
                        // TODO: this is duplicated work as getImports
                        let chainedImport = imports[Int(bind.ordinal)]
                        let symbolName = chainedImport.symbolName ?? "no symbol"
                        print("BIND   ", bind, symbolName)
                    } else {
                        let rebase = data.extract(dyld_chained_ptr_64_rebase.self)
                        print("REBASE   ", rebase)
                    }

                    if bind.next == 0 {
                        done = true
                    } else {
                        chainedOffset += UInt32(bind.next) * 4
                    }
                    // DYLD_CHAINED_PTR_32
                } else if segmentInfo.pointerFormat == 3 {

                    let data = file.base.advanced(by: Int(chainedOffset))
                    let bind = data.extract(dyld_chained_ptr_32_bind.self)
                    if bind.bind {
                        print("BIND   ", bind)
                    } else {
                        let rebase = data.extract(dyld_chained_ptr_32_rebase.self)
                        print("REBASE   ", rebase)
                    }

                    if bind.next == 0 {
                        done = true
                    } else {
                        chainedOffset += bind.next * 4
                    }
                } else {
                    print("Unsupported format", segmentInfo.pointerFormat)
                    done = true
                    break
                }
            }
        }
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
