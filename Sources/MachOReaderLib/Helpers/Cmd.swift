import Foundation

public struct Cmd: RawRepresentable, Equatable, Hashable {

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
        case .buildVersion: return "LC_BUILD_VERSION"
        case .codeSignature: return "LC_CODE_SIGNATURE"
        case .dataInCode: return "LC_DATA_IN_CODE"
        case .dyldChainedFixups: return "LC_DYLD_CHAINED_FIXUPS"
        case .dyldEnvironment: return "LC_DYLD_ENVIRONMENT"
        case .dyldExportsTrie: return "LC_DYLD_EXPORTS_TRIE"
        case .dylibCodeSignDrs: return "LC_DYLIB_CODE_SIGN_DRS"
        case .dysymtab: return "LC_DYSYMTAB"
        case .functionStarts: return "LC_FUNCTION_STARTS"
        case .idDylib: return "LC_ID_DYLIB"
        case .idDylinker: return "LC_ID_DYLINKER"
        case .linkerOptimizationHint: return "LC_LINKER_OPTIMIZATION_HINT"
        case .loadDylib: return "LC_LOAD_DYLIB"
        case .loadDylinker: return "LC_LOAD_DYLINKER"
        case .loadWeakDylib: return "LC_LOAD_WEAK_DYLIB"
        case .main: return "LC_MAIN"
        case .reexportDylib: return "LC_REEXPORT_DYLIB"
        case .segment: return "LC_SEGMENT"
        case .segment64: return "LC_SEGMENT_64"
        case .segmentSplitInfo: return "LC_SEGMENT_SPLIT_INFO"
        case .sourceVersion: return "LC_SOURCE_VERSION"
        case .symtab: return "LC_SYMTAB"
        case .thread: return "LC_THREAD"
        case .unixthread: return "LC_UNIXTHREAD"
        case .uuid: return "LC_UUID"
        default: return nil
        }
    }
}
