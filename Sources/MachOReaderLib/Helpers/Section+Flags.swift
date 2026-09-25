import Foundation
import MachO

public extension SegmentCommand.Section {

    /// The section type: the low byte of `flags` (the `SECTION_TYPE` mask).
    ///
    /// Example: `S_REGULAR`, `S_CSTRING_LITERALS`.
    var type: String? {
        switch flags & UInt32(SECTION_TYPE) {
        case UInt32(S_REGULAR): "S_REGULAR"
        case UInt32(S_ZEROFILL): "S_ZEROFILL"
        case UInt32(S_CSTRING_LITERALS): "S_CSTRING_LITERALS"
        case UInt32(S_4BYTE_LITERALS): "S_4BYTE_LITERALS"
        case UInt32(S_8BYTE_LITERALS): "S_8BYTE_LITERALS"
        case UInt32(S_LITERAL_POINTERS): "S_LITERAL_POINTERS"
        case UInt32(S_NON_LAZY_SYMBOL_POINTERS): "S_NON_LAZY_SYMBOL_POINTERS"
        case UInt32(S_LAZY_SYMBOL_POINTERS): "S_LAZY_SYMBOL_POINTERS"
        case UInt32(S_SYMBOL_STUBS): "S_SYMBOL_STUBS"
        case UInt32(S_MOD_INIT_FUNC_POINTERS): "S_MOD_INIT_FUNC_POINTERS"
        case UInt32(S_MOD_TERM_FUNC_POINTERS): "S_MOD_TERM_FUNC_POINTERS"
        case UInt32(S_COALESCED): "S_COALESCED"
        case UInt32(S_GB_ZEROFILL): "S_GB_ZEROFILL"
        case UInt32(S_INTERPOSING): "S_INTERPOSING"
        case UInt32(S_16BYTE_LITERALS): "S_16BYTE_LITERALS"
        case UInt32(S_DTRACE_DOF): "S_DTRACE_DOF"
        case UInt32(S_LAZY_DYLIB_SYMBOL_POINTERS): "S_LAZY_DYLIB_SYMBOL_POINTERS"
        case UInt32(S_THREAD_LOCAL_REGULAR): "S_THREAD_LOCAL_REGULAR"
        case UInt32(S_THREAD_LOCAL_ZEROFILL): "S_THREAD_LOCAL_ZEROFILL"
        case UInt32(S_THREAD_LOCAL_VARIABLES): "S_THREAD_LOCAL_VARIABLES"
        case UInt32(S_THREAD_LOCAL_VARIABLE_POINTERS): "S_THREAD_LOCAL_VARIABLE_POINTERS"
        case UInt32(S_THREAD_LOCAL_INIT_FUNCTION_POINTERS): "S_THREAD_LOCAL_INIT_FUNCTION_POINTERS"
        case UInt32(S_INIT_FUNC_OFFSETS): "S_INIT_FUNC_OFFSETS"
        default: nil
        }
    }

    /// The section attributes: the high 24 bits of `flags` (the `SECTION_ATTRIBUTES` mask).
    ///
    /// Example: `["S_ATTR_PURE_INSTRUCTIONS", "S_ATTR_SOME_INSTRUCTIONS"]`.
    var attributes: [String] {
        let mask = flags & SECTION_ATTRIBUTES
        var result = [String]()

        if mask & UInt32(S_ATTR_PURE_INSTRUCTIONS) != 0 {
            result.append("S_ATTR_PURE_INSTRUCTIONS")
        }
        if mask & UInt32(S_ATTR_NO_TOC) != 0 {
            result.append("S_ATTR_NO_TOC")
        }
        if mask & UInt32(S_ATTR_STRIP_STATIC_SYMS) != 0 {
            result.append("S_ATTR_STRIP_STATIC_SYMS")
        }
        if mask & UInt32(S_ATTR_NO_DEAD_STRIP) != 0 {
            result.append("S_ATTR_NO_DEAD_STRIP")
        }
        if mask & UInt32(S_ATTR_LIVE_SUPPORT) != 0 {
            result.append("S_ATTR_LIVE_SUPPORT")
        }
        if mask & UInt32(S_ATTR_SELF_MODIFYING_CODE) != 0 {
            result.append("S_ATTR_SELF_MODIFYING_CODE")
        }
        if mask & UInt32(S_ATTR_DEBUG) != 0 {
            result.append("S_ATTR_DEBUG")
        }
        if mask & UInt32(S_ATTR_SOME_INSTRUCTIONS) != 0 {
            result.append("S_ATTR_SOME_INSTRUCTIONS")
        }
        if mask & UInt32(S_ATTR_EXT_RELOC) != 0 {
            result.append("S_ATTR_EXT_RELOC")
        }
        if mask & UInt32(S_ATTR_LOC_RELOC) != 0 {
            result.append("S_ATTR_LOC_RELOC")
        }

        return result
    }
}
