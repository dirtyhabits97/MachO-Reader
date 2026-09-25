import Foundation

public extension BinaryDecoder {

    // MARK: - LEB128

    /// Decodes an unsigned LEB128 integer at the current position and advances past it.
    mutating func decodeULEB128() throws -> UInt64 {
        let (value, size) = try decodeULEB128(at: currentPosition)
        try skip(size)
        return value
    }

    /// Decodes a signed LEB128 integer at the current position and advances past it.
    mutating func decodeSLEB128() throws -> Int64 {
        let (value, size) = try decodeSLEB128(at: currentPosition)
        try skip(size)
        return value
    }

    /// Decodes an unsigned LEB128 integer at `offset`.
    ///
    /// - Returns: The decoded value and the number of bytes consumed.
    func decodeULEB128(at offset: Int) throws -> (value: UInt64, size: Int) {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var index = offset

        while true {
            let byte = try decode(UInt8.self, at: index)
            index += 1
            // ponytail: > 63 means more than 10 bytes, which can't fit a UInt64.
            guard shift <= 63 else {
                throw BinaryDecodingError.invalidString(reason: "ULEB128 value at \(offset) exceeds 64 bits")
            }
            result |= UInt64(byte & 0x7F) << shift
            shift += 7
            if byte & 0x80 == 0 {
                break
            }
        }

        return (result, index - offset)
    }

    /// Decodes a signed LEB128 integer at `offset`.
    ///
    /// - Returns: The decoded value and the number of bytes consumed.
    func decodeSLEB128(at offset: Int) throws -> (value: Int64, size: Int) {
        var result: Int64 = 0
        var shift: Int64 = 0
        var index = offset
        var byte: UInt8

        repeat {
            byte = try decode(UInt8.self, at: index)
            index += 1
            guard shift <= 63 else {
                throw BinaryDecodingError.invalidString(reason: "SLEB128 value at \(offset) exceeds 64 bits")
            }
            result |= Int64(byte & 0x7F) << shift
            shift += 7
        } while byte & 0x80 != 0

        // Sign-extend if the sign bit of the last byte is set.
        if shift < 64, byte & 0x40 != 0 {
            result |= -(Int64(1) << shift)
        }

        return (result, index - offset)
    }
}
