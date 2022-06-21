import Foundation

public struct DyldChainedFixupsReport {

    // MARK: - Properties

    private let file: MachOFile

    // MARK: - Methods

    func makeReport() -> Report {
        guard let dyldChainedFixups = getDyldChainedFixups() else {
            fatalError("Expected a DyldChainedFixups command in the macho file.")
        }

        // The pointer to __LINKED it segment where the LC_DYLD_CHAINED_FIXUPS payload lives.
        let baseData = file.base.advanced(by: Int(dyldChainedFixups.dataoff))

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

        // TODO: get startsInSegment data
        return Report(header: header,
                      startsInImage: startsInImage,
                      startsInSegment: startsInSegments,
                      imports: imports)
    }

    private func getSegmentInfo(
        using header: dyld_chained_fixups_header,
        startsInImage: dyld_chained_starts_in_image
    ) -> [dyld_chained_starts_in_segment] {
        let segmentCommands = getSegmentCommands()
        var result: [dyld_chained_starts_in_segment] = []

        for idx in 0 ..< Int(startsInImage.segCount) {
            let segment = segmentCommands[idx]
            let offset = startsInImage.segInfoOffset[idx]

            // NO PAGES
            if offset == 0 { continue }

            // calculate offset
            let segmentOffset = Int(header.startsOffset) + Int(offset)
            let startsInSegment = file.base
                .advanced(by: segmentOffset)
                .extract(dyld_chained_starts_in_segment.self)

            result.append(startsInSegment)
        }

        // TODO: implement this
        return result
    }

    private func getImports(using header: dyld_chained_fixups_header) -> [dyld_chained_import] {
        let dylibCommands = getDylibCommands()
        var result: [dyld_chained_import] = []

        print("IMPORTS...")

        var offset = Int(header.importsOffset)
        for _ in 0 ..< header.importsCount {
            let chainedImport = file.base
                .advanced(by: offset)
                .extract(dyld_chained_import.self)

            // TODO: improve this part of the code
            let name = dylibCommands[Int(chainedImport.libOrdinal) - 1]
                .dylib
                .name
                .split(separator: "/")
                .last!

            let offsetToSymbolName = 0 + header.symbolsOffset + chainedImport.nameOffset
            let symbolName = file.base
                .advanced(by: Int(offsetToSymbolName))
                .extractString()!

            print(chainedImport, "\(name): \(symbolName)")
            result.append(chainedImport)
            // TODO: make it easier for CModels to propose their own size.
            offset += MemoryLayout<UInt32>.size
        }

        return result
    }

    // MARK: - Helpers

    // TODO: consider maknig these part of [LoadCommand] or create a custom wrapper type.
    private func getDyldChainedFixups() -> LinkedItDataCommand? {
        file.commands
            .lazy
            .filter { loadCommand in loadCommand.cmd == .dyldChainedFixups }
            .compactMap { loadCommand -> LinkedItDataCommand? in
                guard case let .linkedItDataCommand(linkedItDataCommand) = loadCommand.commandType() else { return nil }
                return linkedItDataCommand
            }
            .first
    }

    private func getDylibCommands() -> [DylibCommand] {
        file.commands.compactMap { loadCommand -> DylibCommand? in
            guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
            return dylibCommand
        }
    }

    private func getSegmentCommands() -> [SegmentCommand] {
        file.commands.compactMap { loadCommand -> SegmentCommand? in
            guard case let .segmentCommand(segmentCommand) = loadCommand.commandType() else { return nil }
            return segmentCommand
        }
    }
}

extension DyldChainedFixupsReport {

    struct Report {

        let header: dyld_chained_fixups_header
        let startsInImage: dyld_chained_starts_in_image
        let startsInSegment: [dyld_chained_starts_in_segment]
        let imports: [dyld_chained_import]
        // TODO: consider adding an array of tuples with the name of the linked libraries and the symbols
    }
}
