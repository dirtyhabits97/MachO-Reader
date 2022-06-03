import Foundation

enum CLIFormatter {

    static func print(_ output: CLIOutput) {
        Swift.print(output.cli)
    }
}

protocol CLIOutput {

    var cli: String { get  }
}

extension FatHeader: CLIOutput {

    var cli: String {
        var str = "FAT HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
        str += "magic: \(magic.description.padding(toLength: 25, withPad: " ", startingAt: 0))"
        str += "nfat_archs: \(archs.count)"

        for (idx, arch) in archs.enumerated() {
            str += "\n[\(idx)] \(arch.cli)"
        }

        return str
    }
}

extension FatHeader.Architecture: CLIOutput {

    // TODO: for some reason, the cpu subtype is not matching otool
    var cli: String {
        var str = "cputype: \(cputype.cli)".padding(toLength: 30, withPad: " ", startingAt: 0)
        str += "cpusubtype: \(String(cpuSubtype).padding(toLength: 15, withPad: " ", startingAt: 0))"
        str += "offset: \(String(offset).padding(toLength: 10, withPad: " ", startingAt: 0))"
        str += "size: \(String(size).padding(toLength: 10, withPad: " ", startingAt: 0))"
        str += "alignt: 2^\(align)"
        return str
    }
}

extension CPUType: CLIOutput {

    var cli: String {
        let readable: String
        switch self {
        case .x86: readable = "x86"
        case .x86_64: readable = "x86_64"
        case .arm: readable = "ARM"
        case .arm_64: readable = "ARM64"
        default: return String(rawValue)
        }
        return "\(readable.padding(toLength: 7, withPad: " ", startingAt: 0)) (\(rawValue))"
    }
}
