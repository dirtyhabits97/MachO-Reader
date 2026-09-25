import MachO
@testable import MachOReaderLib
import XCTest

final class RpathCommandTests: XCTestCase {

    // MARK: - Tests

    func test_decodesPath_fromRawBytes() {
        let path = "@executable_path/../Frameworks"
        let loadCommand = makeRpathLoadCommand(path: path)

        let rpathCommand = try RpathCommand(from: loadCommand)

        XCTAssertEqual(rpathCommand.path, path)
    }

    func test_allowedCmds_containsRpath() {
        XCTAssertTrue(RpathCommand.allowedCmds.contains(.rpath))
    }

    func test_commandType_buildsRpathCommand() {
        let loadCommand = makeRpathLoadCommand(path: "@loader_path")

        guard case let .rpathCommand(rpathCommand) = try loadCommand.commandType() else {
            XCTFail("Expected .rpathCommand")
            return
        }

        XCTAssertEqual(rpathCommand.path, "@loader_path")
    }
}

// MARK: - Helpers

private func makeRpathLoadCommand(path: String) -> LoadCommand {
    let headerSize = 12 // cmd (4) + cmdsize (4) + path.offset (4)
    let stringBytes = Array(path.utf8) + [0] // null terminator
    let unpaddedSize = headerSize + stringBytes.count
    let cmdsize = UInt32(((unpaddedSize + 3) / 4) * 4)
    let padding = Int(cmdsize) - unpaddedSize

    var bytes = [UInt8]()
    bytes.append(contentsOf: littleEndianBytes(Cmd.rpath.rawValue))
    bytes.append(contentsOf: littleEndianBytes(cmdsize))
    bytes.append(contentsOf: littleEndianBytes(UInt32(headerSize)))
    bytes.append(contentsOf: stringBytes)
    bytes.append(contentsOf: [UInt8](repeating: 0, count: padding))

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
