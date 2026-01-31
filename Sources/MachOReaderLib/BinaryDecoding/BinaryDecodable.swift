import Foundation

/// A type that can decode itself from binary data.
///
/// Implement this protocol for types that require custom decoding logic
/// beyond simple memory layout representation.
///
/// ## Example
///
/// ```swift
/// struct CustomHeader: BinaryDecodable {
///     let magic: UInt32
///     let version: UInt16
///     let flags: UInt16
///
///     init(from decoder: inout BinaryDecoder) throws {
///         magic = try decoder.decode(UInt32.self)
///         version = try decoder.decode(UInt16.self)
///         flags = try decoder.decode(UInt16.self)
///     }
/// }
/// ```
public protocol BinaryDecodable {

    /// Creates an instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    init(from decoder: inout BinaryDecoder) throws
}

public extension BinaryDecoder {

    /// Decodes a custom decodable type from the current position.
    ///
    /// - Parameter type: The type to decode.
    /// - Returns: The decoded value.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    mutating func decode<T: BinaryDecodable>(_: T.Type) throws -> T {
        try T(from: &self)
    }

    /// Decodes a custom decodable type at a specific offset.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - offset: The offset to read from.
    /// - Returns: The decoded value.
    /// - Throws: `BinaryDecodingError` if decoding fails.
    func decode<T: BinaryDecodable>(_: T.Type, at offset: Int) throws -> T {
        var decoder = try subdecoder(at: offset)
        return try T(from: &decoder)
    }
}
