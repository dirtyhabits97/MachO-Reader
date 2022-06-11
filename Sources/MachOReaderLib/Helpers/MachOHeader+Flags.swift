import Foundation

public extension MachOHeader {

    struct Flags: OptionSet {

        // MARK: - Properties

        public let rawValue: UInt32

        // MARK: - Lifecycle

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: Int32) {
            self.rawValue = UInt32(rawValue)
        }

        // MARK: - Constants

        /// The object file has no undefined references.
        static let noUndefs = Flags(MH_NOUNDEFS)
        /// The object file is the output of an incremental link
        /// against a base file and can't be link edited again.
        static let incrLink = Flags(MH_INCRLINK)
        /// The object file is input for dynamic linker and can't
        /// be staticly link edited again.
        static let dyldLink = Flags(MH_DYLDLINK)
        /// The object file's undefined references are bound by
        /// the dynamic linker when loaded.
        static let binDatLoad = Flags(MH_BINDATLOAD)
        /// The file has its dynamic undefined references prebound.
        static let preBound = Flags(MH_PREBOUND)
        /// The file has its read-only and read-write segments split.
        static let splitSegs = Flags(MH_SPLIT_SEGS)
        /// [OBSOLETE] The shared library init routine is to be lazily via
        /// caching memory faults to its writeable segments.
        static let lazyInit = Flags(MH_LAZY_INIT)
        /// The image is using two-level name space bindings.
        static let twoLevel = Flags(MH_TWOLEVEL)
        /// The executable is forcing all images to use flat name
        /// space bindings.
        static let forceFlat = Flags(MH_FORCE_FLAT)
        /// This umbrella guarantees no multiple definitions of symbols
        /// in its sub-images so the two-level namespace hints can
        /// always be used.
        static let noMultiDefs = Flags(MH_NOMULTIDEFS)
        /// Do not have dyld notify the prebinding agent about
        /// this executable.
        static let noFixPreBinding = Flags(MH_NOFIXPREBINDING)
        /// The binary is not prebound but can have its prebinding redone.
        /// Only used when MH_PREBOUND is not set.
        static let preBindable = Flags(MH_PREBINDABLE)
        /// Indicates that this binary binds to all two-level namespace
        /// modules of its dependent libraries.
        /// Only used when MH_PREBINDABLE and MH_TWOLEVEL are both set.
        static let allModsBound = Flags(MH_ALLMODSBOUND)
        /// Safe to divide up the sections into sub-sections via symbols
        /// for dead code stripping.
        static let subsectionsViaSymbols = Flags(MH_SUBSECTIONS_VIA_SYMBOLS)
        /// The binary has been canonicalized via the unprebind operation.
        static let canonical = Flags(MH_CANONICAL)
        /// The final linked image contains external weak symbols.
        static let weakDefines = Flags(MH_WEAK_DEFINES)
        /// The final linked image uses weak symbols.
        static let bindsToWeak = Flags(MH_BINDS_TO_WEAK)
        /// When this bit is set, all stacks in the task will be given stack
        /// execution privilege.
        /// Only used in MH_EXECUTE filetypes.
        static let allowStackExecution = Flags(MH_ALLOW_STACK_EXECUTION)
        /// When this bit is set, the binary declares it is safe for use
        /// in processes with uid zero.
        static let rootSafe = Flags(MH_ROOT_SAFE)
        /// When this bit is set, the binary declares it is safe for use
        /// in processes when issetugid() is true.
        static let setUidSafe = Flags(MH_SETUID_SAFE)
        /// When this bit is set on a dylib, the static linker does
        /// not need to examine dependent dylibs to see if any are re-exported.
        static let noReExportedDylibs = Flags(MH_NO_REEXPORTED_DYLIBS)
        /// When this bit is set, the OS will load the main executable at a
        /// random address.
        /// Only used in MH_EXECUTE filetypes.
        static let pie = Flags(MH_PIE)
        /// Only for use on dylibs.
        /// When linking against a dylib that has this bit set, the static linker
        /// will automatically not create a LC_LOAD_DYLIB load command to the dylib
        /// if no symbols are being referenced from the dylib.
        static let deadStrippableDylib = Flags(MH_DEAD_STRIPPABLE_DYLIB)
        /// Contains a section of type S_THREAD_LOCAL_VARIABLES.
        static let hasTlvDescriptors = Flags(MH_HAS_TLV_DESCRIPTORS)
        /// When this bit is set, the OS will run the main executable with a
        /// non-executable heap even on platforms (e.g. i386) that don't require it.
        /// Only used in MH_EXECUTE filetypes
        static let noHeapExecution = Flags(MH_NO_HEAP_EXECUTION)
        /// The code was linked for use in an application extension.
        static let appExtensionSafe = Flags(MH_APP_EXTENSION_SAFE)
        /// The external symbols listed in the nlist symbol table do not include
        /// all the symbols listed in the dyld info.
        static let nListOutOfSyncWithDylidInfo = Flags(MH_NLIST_OUTOFSYNC_WITH_DYLDINFO)
        /// Allow LC_MIN_VERSION_MACOS and LC_BUILD_VERSION load commands with the
        /// platforms macOS, macCatalyst, iOSSimulator, tvOSSimulator and watchOSSimulator.
        static let simSupport = Flags(MH_SIM_SUPPORT)
        /// Only for use on dylibs.
        /// When this bit is set, the dylib is part of the dyld shared cache,
        /// rather than loose in the filesystem.
        static let dylibInCache = Flags(MH_DYLIB_IN_CACHE)
    }
}

// MARK: - Readable

extension MachOHeader.Flags: Readable {

    public var readableValue: String? {
        nil
    }
}
