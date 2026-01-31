import Foundation

extension Data {

    // MARK: - Deprecated Unsafe Methods

    // These methods are kept for backward compatibility but will be removed in a future version.
    // Use BinaryDecoder instead for safe, bounds-checked decoding.

    @available(*, deprecated, message: "Use BinaryDecoder.decode(_:at:) instead for safe decoding")
    func extract<C: CustomExtractable>(_: C.Type) -> C {
        CustomExtractor().extract(from: self)
    }

    @available(*, deprecated, message: "Use BinaryDecoder.decode(_:at:) instead for safe decoding")
    func extract<T>(_: T.Type) -> T {
        UnsafeExtractor().extract(from: self)
    }

    @available(*, deprecated, message: "Use BinaryDecoder.decode(_:count:at:) instead for safe decoding")
    func extractArray<T>(_: T.Type, count: Int) -> [T] {
        ArrayExtractor(count: count).extract(from: self)
    }

    @available(*, deprecated, message: "Use BinaryDecoder.decodeString(maxLength:at:) instead for safe decoding")
    func extractString() -> String? {
        StringExtractor().extract(from: self)
    }
}

protocol Extracting {

    associatedtype Result

    func extract(from data: Data) -> Result
}

struct UnsafeExtractor<Result>: Extracting {

    func extract(from data: Data) -> Result {
        let size = MemoryLayout<Result>.size
        let data = data[..<size]
        return data.withUnsafeBytes { buffer in
            buffer.load(as: Result.self)
        }
    }
}

struct StringExtractor: Extracting {

    func extract(from data: Data) -> String? {
        var bytes = [Data.Element]()
        for byte in data {
            // get all the chars until we hit '\0' delimiter.
            if byte == 0 { break }
            bytes.append(byte)
        }
        return String(bytes: bytes, encoding: .utf8)
    }
}

// TODO: document this
struct ArrayExtractor<Element>: Extracting {

    let count: Int

    func extract(from data: Data) -> [Element] {
        var result = [Element]()
        var offset = 0
        let unsafeExtractor = UnsafeExtractor<Element>()

        for _ in 0 ..< count {
            let pointer = unsafeExtractor.extract(from: data.advanced(by: offset))
            result.append(pointer)
            offset += MemoryLayout.size(ofValue: pointer)
        }

        return result
    }
}

protocol CustomExtractable {

    init(from data: Data)
}

struct CustomExtractor<Result: CustomExtractable>: Extracting {

    func extract(from data: Data) -> Result {
        Result(from: data)
    }
}
