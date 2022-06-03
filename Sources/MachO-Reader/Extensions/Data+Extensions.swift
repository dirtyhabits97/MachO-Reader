import Foundation

extension Data {

    func extract<T>(_ type: T.Type) -> T {
        let size = MemoryLayout<T>.size
        let data = self[..<size]
        return data.withUnsafeBytes({ buffer in
            buffer.load(as: T.self)
        })
    }
}
