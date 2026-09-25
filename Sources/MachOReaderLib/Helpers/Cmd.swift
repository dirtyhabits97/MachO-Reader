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

    static let atomInfo = Cmd(LC_ATOM_INFO)
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
    static let encryptionInfo = Cmd(LC_ENCRYPTION_INFO)
    static let encryptionInfo64 = Cmd(LC_ENCRYPTION_INFO_64)
    static let filesetEntry = Cmd(LC_FILESET_ENTRY)
    static let functionStarts = Cmd(LC_FUNCTION_STARTS)
    static let fvmfile = Cmd(LC_FVMFILE)
    static let idDylib = Cmd(LC_ID_DYLIB)
    static let idDylinker = Cmd(LC_ID_DYLINKER)
    static let idfvmlib = Cmd(LC_IDFVMLIB)
    static let ident = Cmd(LC_IDENT)
    static let lazyLoadDylib = Cmd(LC_LAZY_LOAD_DYLIB)
    static let linkerOptimizationHint = Cmd(LC_LINKER_OPTIMIZATION_HINT)
    static let loadDylib = Cmd(LC_LOAD_DYLIB)
    static let loadDylinker = Cmd(LC_LOAD_DYLINKER)
    static let loadWeakDylib = Cmd(LC_LOAD_WEAK_DYLIB)
    static let loadUpwardDylib = Cmd(LC_LOAD_UPWARD_DYLIB)
    static let loadfvmlib = Cmd(LC_LOADFVMLIB)
    static let main = Cmd(LC_MAIN)
    static let note = Cmd(LC_NOTE)
    static let preboundDylib = Cmd(LC_PREBOUND_DYLIB)
    static let prebindCksum = Cmd(LC_PREBIND_CKSUM)
    static let reexportDylib = Cmd(LC_REEXPORT_DYLIB)
    static let routines = Cmd(LC_ROUTINES)
    static let routines64 = Cmd(LC_ROUTINES_64)
    static let rpath = Cmd(LC_RPATH)
    static let segment = Cmd(LC_SEGMENT)
    static let segmentSplitInfo = Cmd(LC_SEGMENT_SPLIT_INFO)
    static let segment64 = Cmd(LC_SEGMENT_64)
    static let sourceVersion = Cmd(LC_SOURCE_VERSION)
    static let subClient = Cmd(LC_SUB_CLIENT)
    static let subFramework = Cmd(LC_SUB_FRAMEWORK)
    static let subLibrary = Cmd(LC_SUB_LIBRARY)
    static let subUmbrella = Cmd(LC_SUB_UMBRELLA)
    static let symseg = Cmd(LC_SYMSEG)
    static let symtab = Cmd(LC_SYMTAB)
    static let thread = Cmd(LC_THREAD)
    static let twolevelHints = Cmd(LC_TWOLEVEL_HINTS)
    static let unixthread = Cmd(LC_UNIXTHREAD)
    static let uuid = Cmd(LC_UUID)
    static let versionMinIphoneos = Cmd(LC_VERSION_MIN_IPHONEOS)
    static let versionMinMacosx = Cmd(LC_VERSION_MIN_MACOSX)
    static let versionMinTvos = Cmd(LC_VERSION_MIN_TVOS)
    static let versionMinWatchos = Cmd(LC_VERSION_MIN_WATCHOS)
}

// MARK: Readable

extension Cmd: Readable {

    public var readableValue: String? {
        switch self {
        case .atomInfo: "LC_ATOM_INFO"
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
        case .encryptionInfo: "LC_ENCRYPTION_INFO"
        case .encryptionInfo64: "LC_ENCRYPTION_INFO_64"
        case .filesetEntry: "LC_FILESET_ENTRY"
        case .functionStarts: "LC_FUNCTION_STARTS"
        case .fvmfile: "LC_FVMFILE"
        case .idDylib: "LC_ID_DYLIB"
        case .idDylinker: "LC_ID_DYLINKER"
        case .idfvmlib: "LC_IDFVMLIB"
        case .ident: "LC_IDENT"
        case .lazyLoadDylib: "LC_LAZY_LOAD_DYLIB"
        case .linkerOptimizationHint: "LC_LINKER_OPTIMIZATION_HINT"
        case .loadDylib: "LC_LOAD_DYLIB"
        case .loadDylinker: "LC_LOAD_DYLINKER"
        case .loadWeakDylib: "LC_LOAD_WEAK_DYLIB"
        case .loadUpwardDylib: "LC_LOAD_UPWARD_DYLIB"
        case .loadfvmlib: "LC_LOADFVMLIB"
        case .main: "LC_MAIN"
        case .note: "LC_NOTE"
        case .preboundDylib: "LC_PREBOUND_DYLIB"
        case .prebindCksum: "LC_PREBIND_CKSUM"
        case .reexportDylib: "LC_REEXPORT_DYLIB"
        case .routines: "LC_ROUTINES"
        case .routines64: "LC_ROUTINES_64"
        case .rpath: "LC_RPATH"
        case .segment: "LC_SEGMENT"
        case .segment64: "LC_SEGMENT_64"
        case .segmentSplitInfo: "LC_SEGMENT_SPLIT_INFO"
        case .sourceVersion: "LC_SOURCE_VERSION"
        case .subClient: "LC_SUB_CLIENT"
        case .subFramework: "LC_SUB_FRAMEWORK"
        case .subLibrary: "LC_SUB_LIBRARY"
        case .subUmbrella: "LC_SUB_UMBRELLA"
        case .symseg: "LC_SYMSEG"
        case .symtab: "LC_SYMTAB"
        case .thread: "LC_THREAD"
        case .twolevelHints: "LC_TWOLEVEL_HINTS"
        case .unixthread: "LC_UNIXTHREAD"
        case .uuid: "LC_UUID"
        case .versionMinIphoneos: "LC_VERSION_MIN_IPHONEOS"
        case .versionMinMacosx: "LC_VERSION_MIN_MACOSX"
        case .versionMinTvos: "LC_VERSION_MIN_TVOS"
        case .versionMinWatchos: "LC_VERSION_MIN_WATCHOS"
        default: nil
        }
    }
}
