import Foundation
@testable import MachOReaderLib
import XCTest

final class LoadCommandTypeTests: XCTestCase {

    // MARK: - Tests

    func test_commandType_throwsWhenUUIDCommandDataIsTruncated() throws {
        // uuid_command needs 24 bytes (cmd + cmdsize + a 16-byte uuid); this
        // payload only has the 8-byte load_command header (cmdsize claims 8,
        // smaller than uuid_command's real size), so decoding it must throw a
        // BinaryDecodingError instead of crashing via an unsafe memory load.
        var cmd = Cmd.uuid.rawValue
        var cmdsize = UInt32(8)

        var data = Data()
        withUnsafeBytes(of: &cmd) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &cmdsize) { data.append(contentsOf: $0) }

        let loadCommand = try LoadCommand(from: data, isSwapped: false)

        XCTAssertThrowsError(try loadCommand.commandType())
    }
}
