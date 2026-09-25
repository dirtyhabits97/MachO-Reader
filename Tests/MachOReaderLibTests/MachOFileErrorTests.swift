@testable import MachOReaderLib
import XCTest

/// Verifies that malformed or truncated input throws `MachOFileError` (or an underlying
/// `BinaryDecodingError`) instead of crashing, and that architecture selection is strict.
final class MachOFileErrorTests: XCTestCase {

    // MARK: - Truncation Tests

    func test_throws_whenTruncatedTo20Bytes() throws {
        guard let url = url(for: "helloworld") else { return }
        let data = try Data(contentsOf: url).prefix(20)

        XCTAssertThrowsError(try MachOFile(from: data, arch: nil))
    }

    func test_throws_whenTruncatedTo100Bytes() throws {
        guard let url = url(for: "helloworld") else { return }
        let data = try Data(contentsOf: url).prefix(100)

        XCTAssertThrowsError(try MachOFile(from: data, arch: nil))
    }

    func test_throws_whenTruncatedTo2000Bytes() throws {
        guard let url = url(for: "helloworld") else { return }
        let data = try Data(contentsOf: url).prefix(2000)

        XCTAssertThrowsError(try MachOFile(from: data, arch: nil))
    }

    func test_throws_whenFatBinaryTruncatedTo100Bytes() throws {
        // "ls" is a fat binary; truncating past the fat header but before a slice's
        // real content previously crashed by advancing past the end of the data.
        guard let url = url(for: "ls") else { return }
        let data = try Data(contentsOf: url).prefix(100)

        XCTAssertThrowsError(try MachOFile(from: data, arch: nil))
    }

    // MARK: - Arch Selection Tests

    func test_throws_whenUnknownArch() throws {
        guard let url = url(for: "helloworld") else { return }

        XCTAssertThrowsError(try MachOFile(from: url, arch: "mips")) { error in
            XCTAssertEqual(error as? MachOFileError, .unknownArch("mips"))
        }
    }

    func test_throws_whenFatBinaryMissingRequestedArch() throws {
        // "ls" only has x86_64 and arm64 slices.
        guard let url = url(for: "ls") else { return }

        XCTAssertThrowsError(try MachOFile(from: url, arch: "arm")) { error in
            XCTAssertEqual(error as? MachOFileError, .archNotFound(CPUType.arm))
        }
    }

    func test_throws_whenThinBinaryArchDoesNotMatchHeader() throws {
        // "helloworld" is a thin arm64 binary.
        guard let url = url(for: "helloworld") else { return }

        XCTAssertThrowsError(try MachOFile(from: url, arch: "x86_64")) { error in
            XCTAssertEqual(error as? MachOFileError, .archNotFound(CPUType.x86_64))
        }
    }

    func test_doesNotThrow_whenFatBinaryRequestsAvailableArch() throws {
        guard let url = url(for: "ls") else { return }

        XCTAssertNoThrow(try MachOFile(from: url, arch: "arm64"))
    }
}
