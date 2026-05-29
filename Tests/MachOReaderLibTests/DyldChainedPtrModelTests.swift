import Foundation
@testable import MachOReaderLib
import XCTest

/// Unit tests for the bit-field decoding of the DYLD chained-pointer models.
///
/// The only test fixture (`helloworld`) is a plain arm64 binary using
/// `DYLD_CHAINED_PTR_64_OFFSET`, so the arm64e / kernel-cache / cache / firmware
/// models are never exercised by the report-level tests. These tests construct
/// raw values with known bit patterns and assert each field decodes correctly,
/// pinning the `split(using:)` widths against Apple's `mach-o/fixup-chains.h`.
final class DyldChainedPtrModelTests: XCTestCase {

    // MARK: - ARM64E

    func test_arm64eRebase_decodesFields() {
        // target:43, high8:8, next:11, bind:1(==0), auth:1(==0)
        let raw: UInt64 = 0x0000_07FF
            | (UInt64(0xAB) << 43)
            | (UInt64(0x5) << 51)
        let model = DyldChainedPtrArm64eRebase(raw)
        XCTAssertEqual(model.target, 0x07FF)
        XCTAssertEqual(model.high8, 0xAB)
        XCTAssertEqual(model.next, 0x5)
        XCTAssertFalse(model.bind)
        XCTAssertFalse(model.auth)
    }

    func test_arm64eAuthRebase_decodesFields() {
        // target:32, diversity:16, addrDiv:1, key:2, next:11, bind:1(==0), auth:1(==1)
        let raw: UInt64 = 0xDEAD_BEEF
            | (UInt64(0x1234) << 32)
            | (UInt64(1) << 48)
            | (UInt64(0x2) << 49)
            | (UInt64(0x7) << 51)
            | (UInt64(1) << 63)
        let model = DyldChainedPtrArm64eAuthRebase(raw)
        XCTAssertEqual(model.target, 0xDEAD_BEEF)
        XCTAssertEqual(model.diversity, 0x1234)
        XCTAssertTrue(model.addrDiv)
        XCTAssertEqual(model.key, 0x2)
        XCTAssertEqual(model.next, 0x7)
        XCTAssertFalse(model.bind)
        XCTAssertTrue(model.auth)
    }

    func test_arm64eBind_decodesFields() {
        // ordinal:16, zero:16, addend:19, next:11, bind:1(==1), auth:1(==0)
        let raw: UInt64 = 0xBEEF
            | (UInt64(0x5) << 32)
            | (UInt64(0x3) << 51)
            | (UInt64(1) << 62)
        let model = DyldChainedPtrArm64eBind(raw)
        XCTAssertEqual(model.ordinal, 0xBEEF)
        XCTAssertEqual(model.zero, 0)
        XCTAssertEqual(model.addend, 0x5)
        XCTAssertEqual(model.next, 0x3)
        XCTAssertTrue(model.bind)
        XCTAssertFalse(model.auth)
    }

    func test_arm64eAuthBind_decodesFields() {
        // ordinal:16, zero:16, diversity:16, addrDiv:1, key:2, next:11, bind:1(==1), auth:1(==1)
        let raw: UInt64 = 0x00FF
            | (UInt64(0x1234) << 32)
            | (UInt64(1) << 48)
            | (UInt64(0x1) << 49)
            | (UInt64(0x2) << 51)
            | (UInt64(1) << 62)
            | (UInt64(1) << 63)
        let model = DyldChainedPtrArm64eAuthBind(raw)
        XCTAssertEqual(model.ordinal, 0x00FF)
        XCTAssertEqual(model.zero, 0)
        XCTAssertEqual(model.diversity, 0x1234)
        XCTAssertTrue(model.addrDiv)
        XCTAssertEqual(model.key, 0x1)
        XCTAssertEqual(model.next, 0x2)
        XCTAssertTrue(model.bind)
        XCTAssertTrue(model.auth)
    }

    // MARK: - ARM64E USERLAND24 (24-bit ordinal binds)

    func test_arm64eBind24_decodesFields() {
        // ordinal:24, zero:8, addend:19, next:11, bind:1(==1), auth:1(==0)
        let raw: UInt64 = 0x123456
            | (UInt64(0x5) << 32)
            | (UInt64(0x7) << 51)
            | (UInt64(1) << 62)
        let model = DyldChainedPtrArm64eBind24(raw)
        XCTAssertEqual(model.ordinal, 0x123456)
        XCTAssertEqual(model.zero, 0)
        XCTAssertEqual(model.addend, 0x5)
        XCTAssertEqual(model.next, 0x7)
        XCTAssertTrue(model.bind)
        XCTAssertFalse(model.auth)
    }

    func test_arm64eAuthBind24_decodesFields() {
        // ordinal:24, zero:8, diversity:16, addrDiv:1, key:2, next:11, bind:1(==1), auth:1(==1)
        let raw: UInt64 = 0xABCDEF
            | (UInt64(0x1234) << 32)
            | (UInt64(1) << 48)
            | (UInt64(0x2) << 49)
            | (UInt64(0x3) << 51)
            | (UInt64(1) << 62)
            | (UInt64(1) << 63)
        let model = DyldChainedPtrArm64eAuthBind24(raw)
        XCTAssertEqual(model.ordinal, 0xABCDEF)
        XCTAssertEqual(model.zero, 0)
        XCTAssertEqual(model.diversity, 0x1234)
        XCTAssertTrue(model.addrDiv)
        XCTAssertEqual(model.key, 0x2)
        XCTAssertEqual(model.next, 0x3)
        XCTAssertTrue(model.bind)
        XCTAssertTrue(model.auth)
    }

    // MARK: - Kernel cache / cache / firmware

    func test_kernelCacheRebase_decodesFields() {
        // target:30, cacheLevel:2, diversity:16, addrDiv:1, key:2, next:12, isAuth:1
        let raw: UInt64 = 0x1000
            | (UInt64(0x2) << 30)
            | (UInt64(0xABCD) << 32)
            | (UInt64(1) << 48)
            | (UInt64(0x3) << 49)
            | (UInt64(0x10) << 51)
            | (UInt64(1) << 63)
        let model = DyldChainedPtr64KernelCacheRebase(raw)
        XCTAssertEqual(model.target, 0x1000)
        XCTAssertEqual(model.cacheLevel, 0x2)
        XCTAssertEqual(model.diversity, 0xABCD)
        XCTAssertEqual(model.addrDiv, 1)
        XCTAssertEqual(model.key, 0x3)
        XCTAssertEqual(model.next, 0x10)
        XCTAssertTrue(model.isAuth)
    }

    func test_cacheRebase32_decodesFields() {
        // target:30, next:2
        let raw: UInt32 = 0x100 | (UInt32(0x2) << 30)
        let model = DyldChainedPtr32CacheRebase(raw)
        XCTAssertEqual(model.target, 0x100)
        XCTAssertEqual(model.next, 0x2)
    }

    func test_firmwareRebase32_decodesFields() {
        // target:26, next:6
        let raw: UInt32 = 0x100 | (UInt32(0x5) << 26)
        let model = DyldChainedPtr32FirmwareRebase(raw)
        XCTAssertEqual(model.target, 0x100)
        XCTAssertEqual(model.next, 0x5)
    }
}
