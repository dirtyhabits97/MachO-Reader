import Foundation
import MachO

/**
 * The linkedit_data_command contains the offsets and sizes of a blob
 * of data in the __LINKEDIT segment.
 */
@dynamicMemberLookup
public struct LinkedItDataCommand: LoadCommandTypeRepresentable {

    // MARK: - Properties

    // struct linkedit_data_command {
    //     uint32_t	cmd;		/* LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO,
    //            LC_FUNCTION_STARTS, LC_DATA_IN_CODE,
    //            LC_DYLIB_CODE_SIGN_DRS,
    //            LC_LINKER_OPTIMIZATION_HINT,
    //            LC_DYLD_EXPORTS_TRIE, or
    //            LC_DYLD_CHAINED_FIXUPS. */
    //     uint32_t	cmdsize;	/* sizeof(struct linkedit_data_command) */
    //     uint32_t	dataoff;	/* file offset of data in __LINKEDIT segment */
    //     uint32_t	datasize;	/* file size of data in __LINKEDIT segment  */
    // };
    private let underlyingValue: linkedit_data_command

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(LinkedItDataCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(LinkedItDataCommand.allowedCmds)")

        var linkedItDataCommand = loadCommand.data.extract(linkedit_data_command.self)

        if loadCommand.isSwapped {
            swap_linkedit_data_command(&linkedItDataCommand, kByteSwapOrder)
        }

        underlyingValue = linkedItDataCommand
    }

    // MARK: - Methods

    public subscript<T>(dynamicMember keyPath: KeyPath<linkedit_data_command, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [
            .codeSignature,
            .segmentSplitInfo,
            .functionStarts,
            .dataInCode,
            .dylibCodeSignDrs,
            .linkerOptimizationHint,
            .dyldExportsTrie,
            .dyldChainedFixups,
        ]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .linkedItDataCommand(LinkedItDataCommand(from: loadCommand))
    }
}
