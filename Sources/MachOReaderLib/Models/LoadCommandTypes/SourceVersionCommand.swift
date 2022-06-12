import Foundation
import MachO

/**
 * The source_version_command is an optional load command containing
 * the version of the sources used to build the binary.
 */
public struct SourceVersionCommand: LoadCommandTypeRepresentable, LoadCommandTransformable {

    // MARK: - Properties

    private let underlyingValue: source_version_command
    private let loadCommand: LoadCommand

    // MARK: - Lifecycle

    init(from loadCommand: LoadCommand) {
        assert(loadCommand.is(SourceVersionCommand.self),
               "\(loadCommand.cmd) doesn't match any of \(SourceVersionCommand.allowedCmds)")

        var sourceVersionCommand = loadCommand.data.extract(source_version_command.self)

        if loadCommand.isSwapped {
            swap_source_version_command(&sourceVersionCommand, kByteSwapOrder)
        }

        self.init(sourceVersionCommand, loadCommand: loadCommand)
    }

    // struct source_version_command {
    //     uint32_t  cmd;	/* LC_SOURCE_VERSION */
    //     uint32_t  cmdsize;	/* 16 */
    //     uint64_t  version;	/* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
    // };
    private init(_ sourceVersionCommand: source_version_command, loadCommand: LoadCommand) {
        self.loadCommand = loadCommand
        underlyingValue = sourceVersionCommand
    }

    // MARK: - LoadCommandTypeRepresentable

    static var allowedCmds: Set<Cmd> { [.sourceVersion] }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType {
        .sourceVersionCommand(SourceVersionCommand(from: loadCommand))
    }

    // MARK: - LoadCommandTransformable

    public func asLoadCommand() -> LoadCommand {
        loadCommand
    }
}

// MARK: - Helpers

public extension SourceVersionCommand {

    typealias SourceVersion = (
        A: Int,
        B: Int,
        C: Int,
        D: Int,
        E: Int
    )

    // uint64_t  version;	/* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
    var version: SourceVersion {
        let mask: UInt64 = 0b1111
        return (
            Int(underlyingValue.version << 40),
            Int(underlyingValue.version << 30 & mask),
            Int(underlyingValue.version << 20 & mask),
            Int(underlyingValue.version << 10 & mask),
            Int(underlyingValue.version & mask)
        )
    }
}
