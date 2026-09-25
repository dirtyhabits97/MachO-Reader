import MachO
@testable import MachOReaderLib
import XCTest

final class VersionMinCommandTests: XCTestCase {

    // MARK: - Tests

    func test_decodesVersionAndSdk_fromRawBytes() {
        // major:12, minor:3, patch:1
        let versionRaw: UInt32 = (12 << 16) | (3 << 8) | 1
        // major:13, minor:0, patch:0
        let sdkRaw: UInt32 = 13 << 16
        let loadCommand = makeVersionMinLoadCommand(cmd: .versionMinMacosx, version: versionRaw, sdk: sdkRaw)

        let versionMinCommand = try VersionMinCommand(from: loadCommand)

        XCTAssertEqual("\(versionMinCommand.version)", "12.3.1")
        XCTAssertEqual("\(versionMinCommand.sdk)", "13.0.0")
    }

    func test_allowedCmds_containsAllVersionMinVariants() {
        XCTAssertEqual(VersionMinCommand.allowedCmds, [
            .versionMinMacosx, .versionMinIphoneos, .versionMinTvos, .versionMinWatchos,
        ])
    }

    func test_commandType_buildsVersionMinCommand() {
        let loadCommand = makeVersionMinLoadCommand(cmd: .versionMinIphoneos, version: 1 << 16, sdk: 2 << 16)

        guard case let .versionMinCommand(versionMinCommand) = try loadCommand.commandType() else {
            XCTFail("Expected .versionMinCommand")
            return
        }

        XCTAssertEqual("\(versionMinCommand.version)", "1.0.0")
        XCTAssertEqual("\(versionMinCommand.sdk)", "2.0.0")
    }
}

// MARK: - Helpers

private func makeVersionMinLoadCommand(cmd: Cmd, version: UInt32, sdk: UInt32) -> LoadCommand {
    var bytes = [UInt8]()
    bytes.append(contentsOf: littleEndianBytes(cmd.rawValue))
    bytes.append(contentsOf: littleEndianBytes(16)) // sizeof(version_min_command)
    bytes.append(contentsOf: littleEndianBytes(version))
    bytes.append(contentsOf: littleEndianBytes(sdk))

    return try LoadCommand(from: Data(bytes), isSwapped: false)
}

private func littleEndianBytes(_ value: UInt32) -> [UInt8] {
    [
        UInt8(value & 0xFF),
        UInt8((value >> 8) & 0xFF),
        UInt8((value >> 16) & 0xFF),
        UInt8((value >> 24) & 0xFF),
    ]
}
