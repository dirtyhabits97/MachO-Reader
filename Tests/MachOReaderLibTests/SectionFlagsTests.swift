import MachO
@testable import MachOReaderLib
import XCTest

final class SectionFlagsTests: XCTestCase {

    // MARK: - Section Type / Attributes

    /// __TEXT,__text in the `ls` fixture: regular section, pure + some instructions.
    func test_type_and_attributes_forTextSection() {
        let section = makeSection(flags: 0x8000_0400)

        XCTAssertEqual(section.type, "S_REGULAR")
        XCTAssertEqual(section.attributes, ["S_ATTR_PURE_INSTRUCTIONS", "S_ATTR_SOME_INSTRUCTIONS"])
    }

    /// __TEXT,__auth_stubs in the `ls` fixture: symbol stubs, pure + some instructions.
    func test_type_and_attributes_forSymbolStubsSection() {
        let section = makeSection(flags: 0x8000_0408)

        XCTAssertEqual(section.type, "S_SYMBOL_STUBS")
        XCTAssertEqual(section.attributes, ["S_ATTR_PURE_INSTRUCTIONS", "S_ATTR_SOME_INSTRUCTIONS"])
    }

    /// __TEXT,__const in the `ls` fixture: regular section, no attributes.
    func test_type_and_attributes_forPlainRegularSection() {
        let section = makeSection(flags: 0x0000_0000)

        XCTAssertEqual(section.type, "S_REGULAR")
        XCTAssertEqual(section.attributes, [])
    }

    func test_type_forCstringLiterals() {
        let section = makeSection(flags: UInt32(S_CSTRING_LITERALS))

        XCTAssertEqual(section.type, "S_CSTRING_LITERALS")
    }

    func test_type_isNil_forUnknownSectionType() {
        let section = makeSection(flags: 0xFF) // not a defined S_* type

        XCTAssertNil(section.type)
    }

    // MARK: - VM Prot

    func test_readableVMProt_forReadExecute() {
        XCTAssertEqual(readableVMProt(VM_PROT_READ | VM_PROT_EXECUTE), "r-x")
    }

    func test_readableVMProt_forReadWrite() {
        XCTAssertEqual(readableVMProt(VM_PROT_READ | VM_PROT_WRITE), "rw-")
    }

    func test_readableVMProt_forNone() {
        XCTAssertEqual(readableVMProt(VM_PROT_NONE), "---")
    }

    func test_readableVMProt_forAll() {
        XCTAssertEqual(readableVMProt(VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE), "rwx")
    }
}

// MARK: - Helpers

private func makeSection(flags: UInt32) -> SegmentCommand.Section {
    var raw = section_64()
    raw.flags = flags
    return SegmentCommand.Section(raw)
}
