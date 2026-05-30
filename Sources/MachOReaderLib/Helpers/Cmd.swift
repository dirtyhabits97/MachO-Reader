import Foundation

public struct Cmd: RawRepresentable, Equatable, Hashable, Sendable {

    // MARK: - Properties

    public let rawValue: UInt32

    // MARK: - Lifecycle

    public init(_ rawValue: Int32) {
        self.rawValue = UInt32(rawValue)
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: - Constants

    static let buildVersion = Cmd(LC_BUILD_VERSION)
    static let codeSignature = Cmd(LC_CODE_SIGNATURE)
    static let dataInCode = Cmd(LC_DATA_IN_CODE)
    static let dyldChainedFixups = Cmd(LC_DYLD_CHAINED_FIXUPS)
    static let dyldEnvironment = Cmd(LC_DYLD_ENVIRONMENT)
    static let dyldExportsTrie = Cmd(LC_DYLD_EXPORTS_TRIE)
    static let dyldInfo = Cmd(LC_DYLD_INFO)
    static let dyldInfoOnly = Cmd(LC_DYLD_INFO_ONLY)
    static let dylibCodeSignDrs = Cmd(LC_DYLIB_CODE_SIGN_DRS)
    static let dysymtab = Cmd(LC_DYSYMTAB)
    static let functionStarts = Cmd(LC_FUNCTION_STARTS)
    static let idDylib = Cmd(LC_ID_DYLIB)
    static let idDylinker = Cmd(LC_ID_DYLINKER)
    static let linkerOptimizationHint = Cmd(LC_LINKER_OPTIMIZATION_HINT)
    static let loadDylib = Cmd(LC_LOAD_DYLIB)
    static let loadDylinker = Cmd(LC_LOAD_DYLINKER)
    static let loadWeakDylib = Cmd(LC_LOAD_WEAK_DYLIB)
    static let main = Cmd(LC_MAIN)
    static let reexportDylib = Cmd(LC_REEXPORT_DYLIB)
    static let segment = Cmd(LC_SEGMENT)
    static let segmentSplitInfo = Cmd(LC_SEGMENT_SPLIT_INFO)
    static let segment64 = Cmd(LC_SEGMENT_64)
    static let sourceVersion = Cmd(LC_SOURCE_VERSION)
    static let symtab = Cmd(LC_SYMTAB)
    static let thread = Cmd(LC_THREAD)
    static let unixthread = Cmd(LC_UNIXTHREAD)
    static let uuid = Cmd(LC_UUID)
}

// MARK: Readable

extension Cmd: Readable {

    public var readableValue: String? {
        switch self {
        case .buildVersion: "LC_BUILD_VERSION"
        case .codeSignature: "LC_CODE_SIGNATURE"
        case .dataInCode: "LC_DATA_IN_CODE"
        case .dyldChainedFixups: "LC_DYLD_CHAINED_FIXUPS"
        case .dyldEnvironment: "LC_DYLD_ENVIRONMENT"
        case .dyldExportsTrie: "LC_DYLD_EXPORTS_TRIE"
        case .dyldInfo: "LC_DYLD_INFO"
        case .dyldInfoOnly: "LC_DYLD_INFO_ONLY"
        case .dylibCodeSignDrs: "LC_DYLIB_CODE_SIGN_DRS"
        case .dysymtab: "LC_DYSYMTAB"
        case .functionStarts: "LC_FUNCTION_STARTS"
        case .idDylib: "LC_ID_DYLIB"
        case .idDylinker: "LC_ID_DYLINKER"
        case .linkerOptimizationHint: "LC_LINKER_OPTIMIZATION_HINT"
        case .loadDylib: "LC_LOAD_DYLIB"
        case .loadDylinker: "LC_LOAD_DYLINKER"
        case .loadWeakDylib: "LC_LOAD_WEAK_DYLIB"
        case .main: "LC_MAIN"
        case .reexportDylib: "LC_REEXPORT_DYLIB"
        case .segment: "LC_SEGMENT"
        case .segment64: "LC_SEGMENT_64"
        case .segmentSplitInfo: "LC_SEGMENT_SPLIT_INFO"
        case .sourceVersion: "LC_SOURCE_VERSION"
        case .symtab: "LC_SYMTAB"
        case .thread: "LC_THREAD"
        case .unixthread: "LC_UNIXTHREAD"
        case .uuid: "LC_UUID"
        default: nil
        }
    }
}
