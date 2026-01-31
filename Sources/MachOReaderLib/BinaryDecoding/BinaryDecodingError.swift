import Foundation

/// Errors that can occur during binary decoding operations.
public enum BinaryDecodingError: Error, CustomStringConvertible {
    
    /// Insufficient data available for the requested type.
    case insufficientData(required: Int, available: Int)
    
    /// Data is not properly aligned for the requested type.
    case misalignedData(required: Int, actual: Int)
    
    /// String data is not valid UTF-8 or exceeds maximum length.
    case invalidString(reason: String)
    
    /// Array count is invalid or exceeds reasonable limits.
    case invalidArrayCount(Int, max: Int)
    
    /// Offset is out of bounds.
    case offsetOutOfBounds(offset: Int, size: Int)
    
    public var description: String {
        switch self {
        case let .insufficientData(required, available):
            return "Insufficient data: required \(required) bytes, but only \(available) available"
        case let .misalignedData(required, actual):
            return "Data misaligned: requires \(required)-byte alignment, but got \(actual)"
        case let .invalidString(reason):
            return "Invalid string: \(reason)"
        case let .invalidArrayCount(count, max):
            return "Invalid array count: \(count) exceeds maximum \(max)"
        case let .offsetOutOfBounds(offset, size):
            return "Offset out of bounds: \(offset) >= \(size)"
        }
    }
}
