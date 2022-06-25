import Foundation

// TODO: remove prints
public struct DyldChainedFixupsReport {

    // MARK: - Properties

    private let file: MachOFile
    /// The pointer to __LINKED it segment where the LC_DYLD_CHAINED_FIXUPS payload lives.
    private let baseData: Data

    // MARK: - Lifecycle

    init(file: MachOFile) {
        guard let dyldChainedFixups = file.commands.getDyldChainedFixups() else {
            fatalError("Expected a DyldChainedFixups command in the macho file.")
        }
        baseData = file.base.advanced(by: Int(dyldChainedFixups.dataoff))
        self.file = file
    }

    // MARK: - Methods

    public func report() -> Report {
        // header of the LC_DYLD_CHAINED_FIXUPS payload
        let header = baseData.extract(dyld_chained_fixups_header.self)

        // each of these comes with a segment offset.
        // in that offset information bind / rebase exist
        // as well as imports
        let startsInImage = baseData
            .advanced(by: Int(header.startsOffset))
            .extract(dyld_chained_starts_in_image.self)

        // the libraries imported by the binary
        let imports = getImports(using: header)

        // TODO: document this
        let startsInSegments = getSegmentInfo(using: header, startsInImage: startsInImage)

        return Report(header: header,
                      startsInImage: startsInImage,
                      startsInSegment: startsInSegments,
                      imports: imports)
    }

    private func getSegmentInfo(
        using header: dyld_chained_fixups_header,
        startsInImage: dyld_chained_starts_in_image
    ) -> [dyld_chained_starts_in_segment] {
        let segmentCommands = file.commands.getSegmentCommands()
        var result: [dyld_chained_starts_in_segment] = []

        for idx in 0 ..< Int(startsInImage.segCount) {
            let segment = segmentCommands[idx]
            let offset = startsInImage.segInfoOffset[idx]
            print("SEGMENT \(segment.segname) (offset: \(offset))")

            // NO PAGES
            if offset == 0 { continue }

            // calculate offset
            let segmentOffset = Int(header.startsOffset) + Int(offset)
            let startsInSegment = baseData
                .advanced(by: segmentOffset)
                .extract(dyld_chained_starts_in_segment.self)

            print(startsInSegment)
            getPageInfo(using: header, segmentInfo: startsInSegment)

            result.append(startsInSegment)
        }

        return result
    }

    // TODO: might need to move this to its own struct / class with how many pointerFormat we want to support
    // TODO: Finish implementing this
    private func getPageInfo(using header: dyld_chained_fixups_header, segmentInfo: dyld_chained_starts_in_segment) {
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
                        let chainedImport = baseData
                            .advanced(by: Int(header.importsOffset) + MemoryLayout<UInt32>.size * Int(bind.ordinal))
                            .extract(dyld_chained_import.self)
                        let offsetToSymbolName = header.symbolsOffset + chainedImport.nameOffset
                        let symbolName = baseData
                            .advanced(by: Int(offsetToSymbolName))
                            .extractString()!
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

    private func getImports(using header: dyld_chained_fixups_header) -> [DyldChainedImport] {
        let dylibCommands = file.commands.getDylibCommands()
        var result: [DyldChainedImport] = []

        print("IMPORTS...")

        var offset = Int(header.importsOffset)
        for _ in 0 ..< header.importsCount {
            var chainedImport = DyldChainedImport(
                baseData
                    .advanced(by: offset)
                    .extract(dyld_chained_import.self)
            )

            chainedImport.dylibName = dylibCommands[Int(chainedImport.libOrdinal) - 1]
                .dylib
                .name
                .split(separator: "/")
                .last?
                .toString()

            let offsetToSymbolName = 0 + header.symbolsOffset + chainedImport.nameOffset
            chainedImport.symbolName = baseData
                .advanced(by: Int(offsetToSymbolName))
                .extractString()

            // TODO: remove this print
            print(chainedImport)
            result.append(chainedImport)
            // TODO: make it easier for CModels to propose their own size.
            offset += MemoryLayout<UInt32>.size
        }

        return result
    }
}

public extension DyldChainedFixupsReport {

    struct Report {

        let header: dyld_chained_fixups_header
        let startsInImage: dyld_chained_starts_in_image
        let startsInSegment: [dyld_chained_starts_in_segment]
        public let imports: [DyldChainedImport]
        // TODO: consider adding an array of tuples with the name of the linked libraries and the symbols
    }
}

private extension Array where Element == LoadCommand {

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
