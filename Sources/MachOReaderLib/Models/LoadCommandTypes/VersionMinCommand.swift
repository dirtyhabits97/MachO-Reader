import Foundation
import MachO

/**
 * The version_min_command contains the min OS version on which this
 * binary was built to run for its platform (before LC_BUILD_VERSION
 * superseded it).
 */
public struct VersionMinCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public let version: SemanticVersion
    public let sdk: SemanticVersion

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(VersionMinCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(VersionMinCommand.allowedCmds)")

        guard var versionMinCommand = try? loadCommand.data.decode(version_min_command.self, at: 0) else {
            fatalError("Failed to decode version_min_command from data of size \(loadCommand.data.count)")
        }

        if loadCommand.isSwapped {
            swap_version_min_command(&versionMinCommand, kByteSwapOrder)
        }

        self.init(versionMinCommand, loadCommand: loadCommand)
    }

    /// struct version_min_command {
    ///     uint32_t	cmd;		/* LC_VERSION_MIN_MACOSX or
    ///              LC_VERSION_MIN_IPHONEOS or
    ///              LC_VERSION_MIN_WATCHOS or
    ///              LC_VERSION_MIN_TVOS */
    ///     uint32_t	cmdsize;	/* sizeof(struct min_version_command) */
    ///     uint32_t	version;	/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    ///     uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    /// };
    private init(_ versionMinCommand: version_min_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        version = SemanticVersion(versionMinCommand.version)
        sdk = SemanticVersion(versionMinCommand.sdk)
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> {
        [.versionMinMacosx, .versionMinIphoneos, .versionMinTvos, .versionMinWatchos]
    }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .versionMinCommand(VersionMinCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}
