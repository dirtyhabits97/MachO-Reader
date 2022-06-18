import Foundation

struct BinaryDecoder<Integer: BinaryInteger> {

    func decode(_ rawValue: Integer, masks: [Integer]) -> [Integer] {
        var prefixSum: Integer = 0
        var result: [Integer] = []
        for mask in masks {
            result.append((rawValue >> prefixSum) & (1 << mask - 1))
            prefixSum += mask
        }
        return result
    }
}

// struct dyld_chained_ptr_64_bind
// {
//     uint64_t    ordinal   : 24,
//                 addend    :  8,   // 0 thru 255
//                 reserved  : 19,   // all zeros
//                 next      : 12,   // 4-byte stride
//                 bind      :  1;   // == 1
// };
// swiftlint:disable:next type_name
struct dyld_chained_ptr_64_bind: CustomExtractable {

    let ordinal: UInt64
    let addend: UInt64
    let reserved: UInt64
    let next: UInt64
    let bind: Bool

    init(from rawValue: UInt64) {
        let values = BinaryDecoder().decode(rawValue, masks: [24, 8, 19, 12, 1])
        ordinal = values[0]
        addend = values[1]
        reserved = values[2]
        next = values[3]
        bind = values[4] == 1
    }

    init(from data: Data) throws {
        self.init(from: data.extract(UInt64.self))
    }
}

protocol CustomExtractable {

    init(from data: Data) throws
}

@dynamicMemberLookup
// swiftlint:disable:next type_name
struct dyld_chained_starts_in_segment: CustomExtractable {

    struct UnderlyingValue {
        let size: UInt32
        let pageSize: UInt16
        let pointerFormat: UInt16
        let segmentOffset: UInt64
        let maxValidPointer: UInt32
        let pageCount: UInt16
    }

    private let underlyingValue: UnderlyingValue
    let pageStart: [UInt16]

    init(from data: Data) throws {
        underlyingValue = data.extract(UnderlyingValue.self)

        var pageStart: [UInt16] = []
        var offset = MemoryLayout.size(ofValue: underlyingValue)

        for _ in 0 ..< underlyingValue.pageCount {
            let pointer = data
                .advanced(by: offset)
                .extract(UInt16.self)
            pageStart.append(pointer)
            offset += MemoryLayout.size(ofValue: pointer)
        }

        self.pageStart = pageStart
    }

    subscript<T>(dynamicMember keyPath: KeyPath<UnderlyingValue, T>) -> T {
        underlyingValue[keyPath: keyPath]
    }
}
