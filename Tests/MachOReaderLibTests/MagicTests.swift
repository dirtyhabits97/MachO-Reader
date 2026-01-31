@testable import MachOReaderLib
import MachO
import XCTest

final class MagicTests: XCTestCase {

    // MARK: - Decoding Tests

    func test_magic_decodesValidMagic64() {
        // MH_MAGIC_64 = 0xfeedfacf (little-endian bytes: cf fa ed fe)
        let data = Data([0xcf, 0xfa, 0xed, 0xfe])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, MH_MAGIC_64)
        XCTAssertTrue(magic.isMagic64)
        XCTAssertFalse(magic.isSwapped)
        XCTAssertFalse(magic.isFat)
    }

    func test_magic_decodesValidMagic32() {
        // MH_MAGIC = 0xfeedface (little-endian bytes: ce fa ed fe)
        let data = Data([0xce, 0xfa, 0xed, 0xfe])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, MH_MAGIC)
        XCTAssertFalse(magic.isMagic64)
        XCTAssertFalse(magic.isSwapped)
    }

    func test_magic_decodesFatMagic() {
        // FAT_MAGIC = 0xcafebabe
        // When read as little-endian UInt32 from bytes [be, ba, fe, ca], we get 0xcafebabe
        let data = Data([0xbe, 0xba, 0xfe, 0xca])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, FAT_MAGIC)
        XCTAssertTrue(magic.isFat)
    }

    func test_magic_decodesSwappedMagic() {
        // MH_CIGAM_64 = 0xcffaedfe (byte-swapped MH_MAGIC_64)
        let data = Data([0xfe, 0xed, 0xfa, 0xcf])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, MH_CIGAM_64)
        XCTAssertTrue(magic.isMagic64)
        XCTAssertTrue(magic.isSwapped)
    }

    // MARK: - Readable Tests

    func test_magic_readableValue_returnsCorrectString() {
        let magic64 = Magic(MH_MAGIC_64)
        let magic32 = Magic(MH_MAGIC)
        let fatMagic = Magic(FAT_MAGIC)

        XCTAssertEqual(magic64.readableValue, "MH_MAGIC_64")
        XCTAssertEqual(magic32.readableValue, "MH_MAGIC")
        XCTAssertEqual(fatMagic.readableValue, "FAT_MAGIC")
    }

    func test_magic_readableValue_returnsNil_whenUnknown() {
        let unknownMagic = Magic(0x12345678)

        XCTAssertNil(unknownMagic.readableValue)
    }

    // MARK: - Validity Tests

    func test_magic_isValid_returnsTrue_forValidMagics() {
        XCTAssertTrue(Magic(MH_MAGIC).isValid)
        XCTAssertTrue(Magic(MH_MAGIC_64).isValid)
        XCTAssertTrue(Magic(MH_CIGAM).isValid)
        XCTAssertTrue(Magic(MH_CIGAM_64).isValid)
        XCTAssertTrue(Magic(FAT_MAGIC).isValid)
        XCTAssertTrue(Magic(FAT_MAGIC_64).isValid)
        XCTAssertTrue(Magic(FAT_CIGAM).isValid)
        XCTAssertTrue(Magic(FAT_CIGAM_64).isValid)
    }

    func test_magic_isValid_returnsFalse_forInvalidMagic() {
        // Shell script shebang read as little-endian: "#!/b" = 0x622f2123
        let shellScriptMagic = Magic(0x622f2123)

        XCTAssertFalse(shellScriptMagic.isValid)
    }
}
