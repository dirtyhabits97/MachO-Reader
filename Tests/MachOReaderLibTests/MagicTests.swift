import MachO
@testable import MachOReaderLib
import XCTest

final class MagicTests: XCTestCase {

    // MARK: - Decoding Tests

    func test_magic_decodesValidMagic64() {
        // MH_MAGIC_64 = 0xfeedfacf (little-endian bytes: cf fa ed fe)
        let data = Data([0xCF, 0xFA, 0xED, 0xFE])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, MH_MAGIC_64)
        XCTAssertTrue(magic.isMagic64)
        XCTAssertFalse(magic.isSwapped)
        XCTAssertFalse(magic.isFat)
    }

    func test_magic_decodesValidMagic32() {
        // MH_MAGIC = 0xfeedface (little-endian bytes: ce fa ed fe)
        let data = Data([0xCE, 0xFA, 0xED, 0xFE])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, MH_MAGIC)
        XCTAssertFalse(magic.isMagic64)
        XCTAssertFalse(magic.isSwapped)
    }

    func test_magic_decodesFatMagic() {
        // FAT_MAGIC = 0xcafebabe
        // When read as little-endian UInt32 from bytes [be, ba, fe, ca], we get 0xcafebabe
        let data = Data([0xBE, 0xBA, 0xFE, 0xCA])

        let magic = Magic(peek: data)

        XCTAssertEqual(magic.rawValue, FAT_MAGIC)
        XCTAssertTrue(magic.isFat)
    }

    func test_magic_decodesSwappedMagic() {
        // MH_CIGAM_64 = 0xcffaedfe (byte-swapped MH_MAGIC_64)
        let data = Data([0xFE, 0xED, 0xFA, 0xCF])

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
        let unknownMagic = Magic(0x1234_5678)

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
        let shellScriptMagic = Magic(0x622F_2123)

        XCTAssertFalse(shellScriptMagic.isValid)
    }
}
