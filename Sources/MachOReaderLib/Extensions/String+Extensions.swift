import Foundation

extension String {

    // source:
    // https://github.com/g-Off/Machismo/blob/master/Sources/Machismo/Extensions/String%2BExtensions.swift
    // swiftlint:disable:next large_tuple line_length
    init(char16 rawCString: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)) {
        var copy = rawCString
        let size = MemoryLayout.size(ofValue: copy)

        self.init(withUnsafePointer(to: &copy) {
            $0.withMemoryRebound(to: CChar.self, capacity: size) {
                String(cString: $0)
            }
        })
    }
}
