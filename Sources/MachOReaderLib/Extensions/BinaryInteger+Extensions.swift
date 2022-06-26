import Foundation

extension BinaryInteger {

    func split(using masks: [Self]) -> [Self] {
        var prefixSum: Self = 0
        var result: [Self] = []
        for mask in masks {
            result.append((self >> prefixSum) & (1 << mask - 1))
            prefixSum += mask
        }
        return result
    }
}

extension RawRepresentable where RawValue: BinaryInteger {

    func split(using masks: [RawValue]) -> [RawValue] {
        rawValue.split(using: masks)
    }
}
