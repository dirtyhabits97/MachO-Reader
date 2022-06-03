import Foundation
import MachO

/**
 * The uuid load command contains a single 128-bit unique random number that
 * identifies an object produced by the static link editor.
 */
struct UUIDCommand {

    // MARK: - Properties

    // struct uuid_command {
    //     uint32_t	cmd;		/* LC_UUID */
    //     uint32_t	cmdsize;	/* sizeof(struct uuid_command) */
    //     uint8_t	uuid[16];	/* the 128-bit uuid */
    // };
    private let underlyingValue: uuid_command

    var uuid: UUID { UUID(uuid: underlyingValue.uuid) }

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var uuidCommand = loadCommand.data.extract(uuid_command.self)

        if loadCommand.isSwapped {
            swap_uuid_command(&uuidCommand, kByteSwapOrder)
        }

        underlyingValue = uuidCommand
    }
}

extension UUIDCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .uuidCommand(UUIDCommand(from: loadCommand))
    }
}

extension UUIDCommand: CustomStringConvertible {

    var description: String { uuid.uuidString }
}
