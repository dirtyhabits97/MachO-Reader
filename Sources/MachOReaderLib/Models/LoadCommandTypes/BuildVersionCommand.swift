import Foundation
import MachO

/**
 * The build_version_command contains the min OS version on which this
 * binary was built to run for its platform.  The list of known platforms and
 * tool values following it.
 */
public struct BuildVersionCommand {

    // MARK: - Properties

    public let platform: Platform
    public let minOS: SemanticVersion
    public let sdk: SemanticVersion

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var buildVersionCommand = loadCommand.data.extract(build_version_command.self)

        if loadCommand.isSwapped {
            swap_build_version_command(&buildVersionCommand, kByteSwapOrder)
        }

        self.init(buildVersionCommand)
    }

    // struct build_version_command {
    //     uint32_t	cmd;		/* LC_BUILD_VERSION */
    //     uint32_t	cmdsize;	/* sizeof(struct build_version_command) plus */
    //         /* ntools * sizeof(struct build_tool_version) */
    //     uint32_t	platform;	/* platform */
    //     uint32_t	minos;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    //     uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    //     uint32_t	ntools;		/* number of tool entries following this */
    // };
    private init(_ buildVersionCommand: build_version_command) {
        platform = Platform(buildVersionCommand.platform)
        minOS = SemanticVersion(buildVersionCommand.minos)
        sdk = SemanticVersion(buildVersionCommand.sdk)
    }
}

extension BuildVersionCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .buildVersionCommand(BuildVersionCommand(from: loadCommand))
    }
}
