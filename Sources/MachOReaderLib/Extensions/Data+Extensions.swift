import Foundation

extension Data {

    func extract<T>(_: T.Type) -> T {
        let size = MemoryLayout<T>.size
        let data = self[..<size]
        return data.withUnsafeBytes { buffer in
            buffer.load(as: T.self)
        }
    }

    func nextString() -> String? {
        var bytes = [Element]()
        for byte in self {
            // get all the chars until we hit '\0' delimiter.
            if byte == 0 { break }
            bytes.append(byte)
        }
        return String(bytes: bytes, encoding: .utf8)
    }
}
