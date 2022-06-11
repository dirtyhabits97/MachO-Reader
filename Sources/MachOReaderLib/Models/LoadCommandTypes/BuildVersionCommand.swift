import Foundation
import MachO

/**
 * The build_version_command contains the min OS version on which this
 * binary was built to run for its platform.  The list of known platforms and
 * tool values following it.
 */
struct BuildVersionCommand {

    // MARK: - Properties

    // struct build_version_command {
    //     uint32_t	cmd;		/* LC_BUILD_VERSION */
    //     uint32_t	cmdsize;	/* sizeof(struct build_version_command) plus */
    //         /* ntools * sizeof(struct build_tool_version) */
    //     uint32_t	platform;	/* platform */
    //     uint32_t	minos;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    //     uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    //     uint32_t	ntools;		/* number of tool entries following this */
    // };
    private let underlyingValue: build_version_command

    var platform: Platform? { Platform(rawValue: Int(underlyingValue.platform)) }
    var minOS: SemanticVersion { SemanticVersion(underlyingValue.minos) }
    var sdk: SemanticVersion { SemanticVersion(underlyingValue.sdk) }

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        var buildVersionCommand = loadCommand.data.extract(build_version_command.self)

        if loadCommand.isSwapped {
            swap_build_version_command(&buildVersionCommand, kByteSwapOrder)
        }

        underlyingValue = buildVersionCommand
    }
}

extension BuildVersionCommand: LoadCommandTypeRepresentable {

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .buildVersionCommand(BuildVersionCommand(from: loadCommand))
    }
}

// MARK: - Helpers

extension BuildVersionCommand {

    // #define PLATFORM_MACOS 1
    // #define PLATFORM_IOS 2
    // #define PLATFORM_TVOS 3
    // #define PLATFORM_WATCHOS 4
    // #define PLATFORM_BRIDGEOS 5
    // #define PLATFORM_MACCATALYST 6
    // #define PLATFORM_IOSSIMULATOR 7
    // #define PLATFORM_TVOSSIMULATOR 8
    // #define PLATFORM_WATCHOSSIMULATOR 9
    // #define PLATFORM_DRIVERKIT 10
    enum Platform: Int, CustomStringConvertible {
        case macOS = 1
        case iOS
        case watchOS
        case bridgeOS
        case macCatalyst
        case iOSSimulator
        case tvOSSimulator
        case watchOSSimulator
        case driverKit

        var description: String {
            switch self {
            case .macOS: return "macOS"
            case .iOS: return "iOS"
            case .watchOS: return "watchOS"
            case .bridgeOS: return "bridgeOS"
            case .macCatalyst: return "macCatalyst"
            case .iOSSimulator: return "iOSSimulator"
            case .tvOSSimulator: return "tvOSSimulator"
            case .watchOSSimulator: return "watchOSSimulator"
            case .driverKit: return "driverKit"
            }
        }
    }
}

extension BuildVersionCommand: CustomStringConvertible {

    var description: String {
        if let platform = platform {
            return "platform: \(platform.description)   minos: \(minOS)   sdk: \(sdk)"
        }
        return "minOS: \(minOS)   sdk: \(sdk)"
    }
}
