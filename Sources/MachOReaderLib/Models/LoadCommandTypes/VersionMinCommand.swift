import Foundation
import MachO

/**
 * The version_min_command contains the min OS version on which this
 * binary was built to run for its platform (before LC_BUILD_VERSION
 * superseded it).
 */
public struct VersionMinCommand: LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public let version: SemanticVersion
    public let sdk: SemanticVersion

    // MARK: - Lifecycle

    /// struct version_min_command {
    ///     uint32_t	cmd;		/* LC_VERSION_MIN_MACOSX or
    ///              LC_VERSION_MIN_IPHONEOS or
    ///              LC_VERSION_MIN_WATCHOS or
    ///              LC_VERSION_MIN_TVOS */
    ///     uint32_t	cmdsize;	/* sizeof(struct min_version_command) */
    ///     uint32_t	version;	/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    ///     uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    /// };
    init(from loadCommand: LoadCommand) throws {
        var versionMinCommand = try loadCommand.data.decode(version_min_command.self)

        if loadCommand.isSwapped {
            swap_version_min_command(&versionMinCommand, kByteSwapOrder)
        }

        self.loadCommand = loadCommand
        version = SemanticVersion(versionMinCommand.version)
        sdk = SemanticVersion(versionMinCommand.sdk)
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
