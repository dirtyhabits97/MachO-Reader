import Foundation
import MachO

/**
 * The uuid load command contains a single 128-bit unique random number that
 * identifies an object produced by the static link editor.
 */
public struct UUIDCommand: LoadCommandTransformable {

    // MARK: - Properties

    private let underlyingValue: uuid_command
    private let loadCommand: LoadCommand

    public var uuid: UUID {
        UUID(uuid: underlyingValue.uuid)
    }

    // MARK: - Lifecycle

    /// struct uuid_command {
    ///     uint32_t	cmd;		/* LC_UUID */
    ///     uint32_t	cmdsize;	/* sizeof(struct uuid_command) */
    ///     uint8_t	uuid[16];	/* the 128-bit uuid */
    /// };
    init(from loadCommand: LoadCommand) throws {
        var uuidCommand = try loadCommand.data.decode(uuid_command.self)

        if loadCommand.isSwapped {
            swap_uuid_command(&uuidCommand, kByteSwapOrder)
        }

        self.loadCommand = loadCommand
        underlyingValue = uuidCommand
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
