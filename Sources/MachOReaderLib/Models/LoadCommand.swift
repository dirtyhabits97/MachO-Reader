import Foundation
import MachO

let kByteSwapOrder = NXByteOrder(0)

/*
 * The load commands directly follow the mach_header.  The total size of all
 * of the commands is given by the sizeofcmds field in the mach_header.  All
 * load commands must have as their first two fields cmd and cmdsize.  The cmd
 * field is filled in with a constant for that command type.  Each command type
 * has a structure specifically for it.  The cmdsize field is the size in bytes
 * of the particular load command structure plus anything that follows it that
 * is a part of the load command (i.e. section structures, strings, etc.).  To
 * advance to the next load command the cmdsize can be added to the offset or
 * pointer of the current load command.  The cmdsize for 32-bit architectures
 * MUST be a multiple of 4 bytes and for 64-bit architectures MUST be a multiple
 * of 8 bytes (these are forever the maximum alignment of any load commands).
 * The padded bytes must be zero.  All tables in the object file must also
 * follow these rules so the file can be memory mapped.  Otherwise the pointers
 * to these tables will not work well or at all on some machines.  With all
 * padding zeroed like objects will compare byte for byte.
 */
public struct LoadCommand {

    // MARK: - Properties

    public let cmd: Cmd
    public let cmdsize: UInt32

    let data: Data
    let isSwapped: Bool

    // MARK: - Lifecycle

    init(from data: Data, isSwapped: Bool) {
        // struct load_command {
        //   uint32_t cmd;		/* type of load command */
        //   uint32_t cmdsize;	/* total size of command in bytes */
        // };
        var loadCommand = data.extract(load_command.self)

        if isSwapped {
            swap_load_command(&loadCommand, kByteSwapOrder)
        }

        cmd = Cmd(loadCommand.cmd)
        cmdsize = loadCommand.cmdsize

        self.data = data
        self.isSwapped = isSwapped
    }

    // MARK: - Methods

    public func commandType() -> LoadCommandType {
        LoadCommandType(from: self)
    }
}
