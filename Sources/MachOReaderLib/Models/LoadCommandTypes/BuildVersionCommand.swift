import Foundation
import MachO

/**
 * The build_version_command contains the min OS version on which this
 * binary was built to run for its platform.  The list of known platforms and
 * tool values following it.
 */
public struct BuildVersionCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    private let loadCommand: LoadCommand

    public let platform: Platform
    public let minOS: SemanticVersion
    public let sdk: SemanticVersion
    public let ntools: UInt32

    public let buildToolVersions: [BuildToolVersion]

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(BuildVersionCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(BuildVersionCommand.allowedCmds)")

        var buildVersionCommand = loadCommand.data.extract(build_version_command.self)

        if loadCommand.isSwapped {
            swap_build_version_command(&buildVersionCommand, kByteSwapOrder)
        }

        self.init(buildVersionCommand, loadCommand: loadCommand)
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
    private init(_ buildVersionCommand: build_version_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand

        platform = Platform(buildVersionCommand.platform)
        minOS = SemanticVersion(buildVersionCommand.minos)
        sdk = SemanticVersion(buildVersionCommand.sdk)

        ntools = buildVersionCommand.ntools

        var buildToolVersions: [BuildToolVersion] = []
        buildToolVersions.reserveCapacity(Int(ntools))

        var offset = MemoryLayout.size(ofValue: buildVersionCommand)
        for _ in 0 ..< ntools {
            let data = loadCommand.data.advanced(by: offset)
            let buildToolVersion = BuildToolVersion(data.extract(build_tool_version.self))
            buildToolVersions.append(buildToolVersion)
            offset += MemoryLayout<build_tool_version>.size
        }

        self.buildToolVersions = buildToolVersions
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> { [.buildVersion] }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .buildVersionCommand(BuildVersionCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}

public extension BuildVersionCommand {

    struct BuildToolVersion {

        public let tool: Tool
        public let version: SemanticVersion

        // struct build_tool_version {
        //     uint32_t	tool;		/* enum for the tool */
        //     uint32_t	version;	/* version number of the tool */
        // };
        init(_ rawValue: build_tool_version) {
            tool = Tool(rawValue.tool)
            version = SemanticVersion(rawValue.version)
        }
    }

    struct Tool: RawRepresentable, Equatable, Readable {

        public var rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: Int32) {
            self.rawValue = UInt32(rawValue)
        }

        static let clang = Tool(TOOL_CLANG)
        static let swift = Tool(TOOL_SWIFT)
        // swiftlint:disable:next identifier_name
        static let ld = Tool(TOOL_LD)
        static let lld = Tool(TOOL_LLD)

        public var readableValue: String? {
            switch self {
            case .clang: return "TOOL_CLANG"
            case .swift: return "TOOL_SWIFT"
            case .ld: return "TOOL_LD"
            case .lld: return "TOOL_LLD"
            default: return nil
            }
        }
    }
}
