import Foundation

/// A type that can decode binary data into structured values.
///
/// `BinaryDecoder` provides safe, bounds-checked access to binary data,
/// similar to `JSONDecoder` but for raw binary formats like Mach-O.
///
/// ## Example
///
/// ```swift
/// let data = Data(...)
/// let decoder = BinaryDecoder(data: data)
///
/// // Decode a simple value
/// let magic: UInt32 = try decoder.decode(UInt32.self)
///
/// // Decode at specific offset
/// let header: mach_header_64 = try decoder.decode(
///     mach_header_64.self,
///     at: 0
/// )
/// ```
public struct BinaryDecoder {

    // MARK: - Properties

    /// The underlying data being decoded.
    private let data: Data

    /// Current read position (for streaming reads).
    private var position: Int = 0

    // MARK: - Lifecycle

    /// Creates a decoder for the specified data.
    ///
    /// - Parameter data: The binary data to decode.
    public init(data: Data) {
        self.data = data
    }

    // MARK: - Decoding Methods

    /// Decodes a value of the specified type from the current position.
    ///
    /// This method advances the internal position by the size of the decoded type.
    ///
    /// - Parameter type: The type to decode.
    /// - Returns: The decoded value.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public mutating func decode<T>(_ type: T.Type) throws -> T {
        let value: T = try decode(type, at: position)
        position += MemoryLayout<T>.size
        return value
    }

    /// Decodes a value of the specified type at a specific offset.
    ///
    /// This method does not advance the internal position.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - offset: The offset to read from.
    /// - Returns: The decoded value.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public func decode<T>(_ type: T.Type, at offset: Int) throws -> T {
        let size = MemoryLayout<T>.size
        let alignment = MemoryLayout<T>.alignment

        // Validate offset is within bounds
        guard offset >= 0, offset < data.count else {
            throw BinaryDecodingError.offsetOutOfBounds(
                offset: offset,
                size: data.count
            )
        }

        // Validate sufficient data
        guard offset + size <= data.count else {
            throw BinaryDecodingError.insufficientData(
                required: size,
                available: data.count - offset
            )
        }

        // Extract data range
        let range = offset ..< (offset + size)
        let subdata = data.subdata(in: range)

        // Decode with alignment handling
        return try subdata.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw BinaryDecodingError.insufficientData(
                    required: size,
                    available: 0
                )
            }

            // Check alignment
            let address = Int(bitPattern: baseAddress)
            if address % alignment != 0 {
                // Copy to aligned temporary buffer
                return try decodeUnaligned(type, from: buffer)
            }

            // Safe to load directly
            return buffer.load(as: T.self)
        }
    }

    /// Decodes an array of values from the current position.
    ///
    /// - Parameters:
    ///   - type: The element type to decode.
    ///   - count: The number of elements to decode.
    ///   - maxCount: Maximum allowed count (safety limit).
    /// - Returns: An array of decoded values.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public mutating func decode<T>(
        _ type: T.Type,
        count: Int,
        maxCount: Int = 10000
    ) throws -> [T] {
        let array: [T] = try decode(type, count: count, maxCount: maxCount, at: position)
        position += MemoryLayout<T>.size * count
        return array
    }

    /// Decodes an array of values at a specific offset.
    ///
    /// - Parameters:
    ///   - type: The element type to decode.
    ///   - count: The number of elements to decode.
    ///   - maxCount: Maximum allowed count (safety limit).
    ///   - offset: The offset to read from.
    /// - Returns: An array of decoded values.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public func decode<T>(
        _ type: T.Type,
        count: Int,
        maxCount: Int = 10000,
        at offset: Int
    ) throws -> [T] {
        // Validate count
        guard count >= 0 else {
            throw BinaryDecodingError.invalidArrayCount(count, max: maxCount)
        }

        guard count <= maxCount else {
            throw BinaryDecodingError.invalidArrayCount(count, max: maxCount)
        }

        let elementSize = MemoryLayout<T>.size
        let totalSize = elementSize * count

        // Validate sufficient data
        guard offset + totalSize <= data.count else {
            throw BinaryDecodingError.insufficientData(
                required: totalSize,
                available: data.count - offset
            )
        }

        // Decode each element
        var result = [T]()
        result.reserveCapacity(count)

        for index in 0 ..< count {
            let elementOffset = offset + (index * elementSize)
            let element = try decode(type, at: elementOffset)
            result.append(element)
        }

        return result
    }

    /// Decodes a null-terminated C string from the current position.
    ///
    /// - Parameter maxLength: Maximum string length (safety limit).
    /// - Returns: The decoded string.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public mutating func decodeString(maxLength: Int = 4096) throws -> String {
        let string = try decodeString(maxLength: maxLength, at: position)
        // Advance position past null terminator
        position += string.utf8.count + 1
        return string
    }

    /// Decodes a null-terminated C string at a specific offset.
    ///
    /// - Parameters:
    ///   - maxLength: Maximum string length (safety limit).
    ///   - offset: The offset to read from.
    /// - Returns: The decoded string.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    public func decodeString(maxLength: Int = 4096, at offset: Int) throws -> String {
        // Validate offset
        guard offset >= 0, offset < data.count else {
            throw BinaryDecodingError.offsetOutOfBounds(
                offset: offset,
                size: data.count
            )
        }

        // Find null terminator
        var bytes = [UInt8]()
        bytes.reserveCapacity(min(256, maxLength))

        let endIndex = min(offset + maxLength, data.count)

        for index in offset ..< endIndex {
            let byte = data[index]

            if byte == 0 {
                // Found null terminator
                guard let string = String(bytes: bytes, encoding: .utf8) else {
                    throw BinaryDecodingError.invalidString(reason: "Not valid UTF-8")
                }
                return string
            }

            bytes.append(byte)
        }

        // No null terminator found within limit
        throw BinaryDecodingError.invalidString(
            reason: "No null terminator found within \(maxLength) bytes"
        )
    }

    /// Creates a new decoder for a subrange of the data.
    ///
    /// - Parameters:
    ///   - offset: The starting offset.
    ///   - length: The length of the subrange (optional).
    /// - Returns: A new decoder for the subrange.
    /// - Throws: `BinaryDecodingError` if the range is invalid.
    public func subdecoder(at offset: Int, length: Int? = nil) throws -> BinaryDecoder {
        guard offset >= 0, offset < data.count else {
            throw BinaryDecodingError.offsetOutOfBounds(
                offset: offset,
                size: data.count
            )
        }

        let endOffset: Int
        if let length = length {
            guard offset + length <= data.count else {
                throw BinaryDecodingError.insufficientData(
                    required: length,
                    available: data.count - offset
                )
            }
            endOffset = offset + length
        } else {
            endOffset = data.count
        }

        let subdata = data.subdata(in: offset ..< endOffset)
        return BinaryDecoder(data: subdata)
    }

    // MARK: - Position Management

    /// The current read position.
    public var currentPosition: Int {
        position
    }

    /// Seeks to a specific position.
    ///
    /// - Parameter offset: The position to seek to.
    /// - Throws: `BinaryDecodingError` if the offset is invalid.
    public mutating func seek(to offset: Int) throws {
        guard offset >= 0, offset <= data.count else {
            throw BinaryDecodingError.offsetOutOfBounds(
                offset: offset,
                size: data.count
            )
        }
        position = offset
    }

    /// Skips forward by the specified number of bytes.
    ///
    /// - Parameter bytes: The number of bytes to skip.
    /// - Throws: `BinaryDecodingError` if skipping would exceed bounds.
    public mutating func skip(_ bytes: Int) throws {
        try seek(to: position + bytes)
    }

    /// The number of bytes remaining from the current position.
    public var bytesRemaining: Int {
        data.count - position
    }

    // MARK: - Private Methods

    /// Decodes a value from misaligned data by copying to an aligned buffer.
    private func decodeUnaligned<T>(_: T.Type, from buffer: UnsafeRawBufferPointer) throws -> T {
        let size = MemoryLayout<T>.size

        // Allocate aligned temporary buffer
        let alignedPointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { alignedPointer.deallocate() }

        // Copy bytes to aligned buffer
        let rawPointer = UnsafeMutableRawPointer(alignedPointer)
        guard let sourceAddress = buffer.baseAddress else {
            throw BinaryDecodingError.insufficientData(required: size, available: 0)
        }
        rawPointer.copyMemory(from: sourceAddress, byteCount: size)

        return alignedPointer.pointee
    }
}

// MARK: - Data Extension

public extension Data {

    /// Creates a binary decoder for this data.
    var binaryDecoder: BinaryDecoder {
        BinaryDecoder(data: self)
    }

    /// Decodes a value from this data at the specified offset.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - offset: The offset to read from (default: 0).
    /// - Returns: The decoded value.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    func decode<T>(_ type: T.Type, at offset: Int = 0) throws -> T {
        try BinaryDecoder(data: self).decode(type, at: offset)
    }
}
