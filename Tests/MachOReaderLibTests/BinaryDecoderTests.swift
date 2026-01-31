@testable import MachOReaderLib
import XCTest

final class BinaryDecoderTests: XCTestCase {

    // MARK: - Basic Decoding Tests

    func test_decodeUInt32_returnsCorrectValue() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        let decoder = BinaryDecoder(data: data)

        let value = try decoder.decode(UInt32.self, at: 0)

        // Little-endian: 0x04030201
        XCTAssertEqual(value, 0x04030201)
    }

    func test_decodeUInt64_returnsCorrectValue() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        let decoder = BinaryDecoder(data: data)

        let value = try decoder.decode(UInt64.self, at: 0)

        // Little-endian: 0x0807060504030201
        XCTAssertEqual(value, 0x0807060504030201)
    }

    func test_decodeAtOffset_returnsCorrectValue() throws {
        let data = Data([0xFF, 0xFF, 0x01, 0x02, 0x03, 0x04])
        let decoder = BinaryDecoder(data: data)

        let value = try decoder.decode(UInt32.self, at: 2)

        XCTAssertEqual(value, 0x04030201)
    }

    // MARK: - Streaming Decode Tests

    func test_streamingDecode_advancesPosition() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])
        var decoder = BinaryDecoder(data: data)

        let first = try decoder.decode(UInt16.self)
        let second = try decoder.decode(UInt16.self)
        let third = try decoder.decode(UInt16.self)

        XCTAssertEqual(first, 0x0201)
        XCTAssertEqual(second, 0x0403)
        XCTAssertEqual(third, 0x0605)
        XCTAssertEqual(decoder.currentPosition, 6)
    }

    func test_streamingDecode_mixedTypes() throws {
        let data = Data([0x01, 0x00, 0x00, 0x00, 0x02, 0x03])
        var decoder = BinaryDecoder(data: data)

        let intValue = try decoder.decode(UInt32.self)
        let byte1 = try decoder.decode(UInt8.self)
        let byte2 = try decoder.decode(UInt8.self)

        XCTAssertEqual(intValue, 1)
        XCTAssertEqual(byte1, 2)
        XCTAssertEqual(byte2, 3)
    }

    // MARK: - Array Decoding Tests

    func test_decodeArray_returnsCorrectValues() throws {
        let data = Data([0x01, 0x00, 0x02, 0x00, 0x03, 0x00])
        let decoder = BinaryDecoder(data: data)

        let array = try decoder.decode(UInt16.self, count: 3, at: 0)

        XCTAssertEqual(array, [1, 2, 3])
    }

    func test_decodeArray_streaming_advancesPosition() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        var decoder = BinaryDecoder(data: data)

        let array = try decoder.decode(UInt8.self, count: 3)

        XCTAssertEqual(array, [1, 2, 3])
        XCTAssertEqual(decoder.currentPosition, 3)
    }

    func test_decodeArray_emptyArray() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        let array = try decoder.decode(UInt8.self, count: 0, at: 0)

        XCTAssertEqual(array, [])
    }

    func test_decodeArray_exceedsMaxCount_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(
            try decoder.decode(UInt8.self, count: 20_000, maxCount: 10_000, at: 0)
        ) { error in
            guard case BinaryDecodingError.invalidArrayCount(20_000, max: 10_000) = error else {
                XCTFail("Expected invalidArrayCount error, got \(error)")
                return
            }
        }
    }

    // MARK: - String Decoding Tests

    func test_decodeString_nullTerminated() throws {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00]) // "Hello\0"
        let decoder = BinaryDecoder(data: data)

        let string = try decoder.decodeString(at: 0)

        XCTAssertEqual(string, "Hello")
    }

    func test_decodeString_streaming_advancesPosition() throws {
        let data = Data([0x48, 0x69, 0x00, 0x42, 0x79, 0x65, 0x00]) // "Hi\0Bye\0"
        var decoder = BinaryDecoder(data: data)

        let first = try decoder.decodeString()
        let second = try decoder.decodeString()

        XCTAssertEqual(first, "Hi")
        XCTAssertEqual(second, "Bye")
    }

    func test_decodeString_emptyString() throws {
        let data = Data([0x00])
        let decoder = BinaryDecoder(data: data)

        let string = try decoder.decodeString(at: 0)

        XCTAssertEqual(string, "")
    }

    func test_decodeString_noNullTerminator_throws() throws {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello" without \0
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decodeString(maxLength: 10, at: 0)) { error in
            guard case BinaryDecodingError.invalidString = error else {
                XCTFail("Expected invalidString error, got \(error)")
                return
            }
        }
    }

    func test_decodeString_exceedsMaxLength_throws() throws {
        let longData = Data(repeating: 0x41, count: 2000) // 'A' * 2000
        let decoder = BinaryDecoder(data: longData)

        XCTAssertThrowsError(try decoder.decodeString(maxLength: 1000, at: 0)) { error in
            guard case BinaryDecodingError.invalidString = error else {
                XCTFail("Expected invalidString error, got \(error)")
                return
            }
        }
    }

    func test_decodeString_invalidUTF8_throws() throws {
        let data = Data([0xFF, 0xFE, 0x00]) // Invalid UTF-8
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decodeString(at: 0)) { error in
            guard case BinaryDecodingError.invalidString = error else {
                XCTFail("Expected invalidString error, got \(error)")
                return
            }
        }
    }

    // MARK: - Error Handling Tests

    func test_decode_insufficientData_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decode(UInt64.self, at: 0)) { error in
            guard case BinaryDecodingError.insufficientData(required: 8, available: 2) = error else {
                XCTFail("Expected insufficientData error, got \(error)")
                return
            }
        }
    }

    func test_decode_offsetOutOfBounds_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decode(UInt32.self, at: 10)) { error in
            guard case BinaryDecodingError.offsetOutOfBounds(offset: 10, size: 2) = error else {
                XCTFail("Expected offsetOutOfBounds error, got \(error)")
                return
            }
        }
    }

    func test_decode_negativeOffset_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decode(UInt32.self, at: -1)) { error in
            guard case BinaryDecodingError.offsetOutOfBounds = error else {
                XCTFail("Expected offsetOutOfBounds error, got \(error)")
                return
            }
        }
    }

    func test_decodeArray_insufficientData_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.decode(UInt32.self, count: 2, at: 0)) { error in
            guard case BinaryDecodingError.insufficientData = error else {
                XCTFail("Expected insufficientData error, got \(error)")
                return
            }
        }
    }

    // MARK: - Subdecoder Tests

    func test_subdecoder_createsNewDecoder() throws {
        let data = Data([0x00, 0x00, 0x01, 0x02, 0x03, 0x04])
        let decoder = BinaryDecoder(data: data)

        let subdecoder = try decoder.subdecoder(at: 2)
        let value = try subdecoder.decode(UInt32.self, at: 0)

        XCTAssertEqual(value, 0x04030201)
    }

    func test_subdecoder_withLength_limitsSize() throws {
        let data = Data([0x00, 0x00, 0x01, 0x02, 0x03, 0x04])
        let decoder = BinaryDecoder(data: data)

        let subdecoder = try decoder.subdecoder(at: 2, length: 2)

        XCTAssertEqual(subdecoder.bytesRemaining, 2)
        XCTAssertThrowsError(try subdecoder.decode(UInt32.self, at: 0))
    }

    func test_subdecoder_invalidOffset_throws() throws {
        let data = Data([0x01, 0x02])
        let decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.subdecoder(at: 10)) { error in
            guard case BinaryDecodingError.offsetOutOfBounds = error else {
                XCTFail("Expected offsetOutOfBounds error, got \(error)")
                return
            }
        }
    }

    // MARK: - Position Management Tests

    func test_seek_setsPosition() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        var decoder = BinaryDecoder(data: data)

        try decoder.seek(to: 2)

        XCTAssertEqual(decoder.currentPosition, 2)
    }

    func test_seek_invalidOffset_throws() throws {
        let data = Data([0x01, 0x02])
        var decoder = BinaryDecoder(data: data)

        XCTAssertThrowsError(try decoder.seek(to: 10)) { error in
            guard case BinaryDecodingError.offsetOutOfBounds = error else {
                XCTFail("Expected offsetOutOfBounds error, got \(error)")
                return
            }
        }
    }

    func test_skip_advancesPosition() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        var decoder = BinaryDecoder(data: data)

        try decoder.skip(2)

        XCTAssertEqual(decoder.currentPosition, 2)
    }

    func test_bytesRemaining_returnsCorrectValue() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        var decoder = BinaryDecoder(data: data)

        XCTAssertEqual(decoder.bytesRemaining, 4)

        _ = try decoder.decode(UInt16.self)

        XCTAssertEqual(decoder.bytesRemaining, 2)
    }

    // MARK: - Data Extension Tests

    func test_dataExtension_decode() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])

        let value: UInt32 = try data.decode(UInt32.self)

        XCTAssertEqual(value, 0x04030201)
    }

    func test_dataExtension_binaryDecoder() {
        let data = Data([0x01, 0x02])

        let decoder = data.binaryDecoder

        XCTAssertEqual(decoder.bytesRemaining, 2)
    }

    // MARK: - Custom Decodable Tests

    func test_customDecodable_decodesCorrectly() throws {
        struct TestStruct: BinaryDecodable {
            let magic: UInt32
            let version: UInt16

            init(from decoder: inout BinaryDecoder) throws {
                magic = try decoder.decode(UInt32.self)
                version = try decoder.decode(UInt16.self)
            }
        }

        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])
        var decoder = BinaryDecoder(data: data)

        let value = try decoder.decode(TestStruct.self)

        XCTAssertEqual(value.magic, 0x04030201)
        XCTAssertEqual(value.version, 0x0605)
    }

    // MARK: - Alignment Tests

    func test_decode_handlesUnalignedData() throws {
        // Create data that might not be aligned
        var data = Data([0xFF]) // Offset by 1 byte
        data.append(contentsOf: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])

        let decoder = BinaryDecoder(data: data)

        // Decode UInt64 from offset 1 (likely misaligned)
        let value = try decoder.decode(UInt64.self, at: 1)

        XCTAssertEqual(value, 0x0807060504030201)
    }
}
