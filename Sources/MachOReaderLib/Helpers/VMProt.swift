import Foundation
import MachO

/// Converts a `vm_prot_t` bitmask into a `"rwx"`-style readable string.
///
/// Example: a `vm_prot_t` with `VM_PROT_READ | VM_PROT_EXECUTE` set becomes `"r-x"`.
public func readableVMProt(_ prot: vm_prot_t) -> String {
    let read = prot & VM_PROT_READ != 0 ? "r" : "-"
    let write = prot & VM_PROT_WRITE != 0 ? "w" : "-"
    let execute = prot & VM_PROT_EXECUTE != 0 ? "x" : "-"
    return "\(read)\(write)\(execute)"
}
