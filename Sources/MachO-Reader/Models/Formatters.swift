// import Foundation

// enum CLIFormatter {

//     static func outputFatHeader(file: MachOFile) {
//         guard let header = file.fatHeader else { return  }
//         var str = "FAT HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
//         str += "magic: \(header.magic.description.padding(toLength: 25, withPad: " ", startingAt: 0))"
//         str += "nfat_archs: \(header.archs.count)"
//         for (idx, arch) in header.archs.enumerated() {
//             str += "\n[\(idx)] \(arch)"
//         }
//         print(str)
//     }

//     static func outputHeader(file: MachOFile) {
//         printHeader(file.header)
//     }

//     static func output(file: MachOFile) {
//         printHeader(file.header)
//         printCommands(file.commands)
//     }
// }

// private extension CLIFormatter {

//     static func printCommands(_ commands: [LoadCommand]) {
//         for command in commands {
//             printCommand(command)
//         }
//     }

//     static func printCommand(_ loadCommand: LoadCommand) {
//         var str = String(hex: loadCommand.cmd).padding(toLength: 20, withPad: " ", startingAt: 0)
//         str += "cmdsize: \(loadCommand.cmdsize)".padding(toLength: 20, withPad: " ", startingAt: 0)
//         str += loadCommand.commandType().description
//         print(str)
//     }
// }

// private extension CLIFormatter {

//     static func printHeader(_ header: MachOHeader) {
//         var str = "MACH_HEADER".padding(toLength: 20, withPad: " ", startingAt: 0)
//         str += "magic: \(header.magic.description.padding(toLength: 13, withPad: " ", startingAt: 0))"
//         str += "cputype: \(header.cputype.description.padding(toLength: 8, withPad: " ", startingAt: 0))"
//         str += "filetype: \(header.filetype.description.padding(toLength: 12, withPad: " ", startingAt: 0))"
//         str += "ncmds: \(header.ncmds)  sizeofcmds: \(header.sizeofcmds)"
//         str += "\n".padding(toLength: 21, withPad: " ", startingAt: 0)
//         str += "flags: \(stringify(flags: header.flags))"

//         print(str)
//     }

//     static func stringify(flags: UInt32) -> String {
//         // TODO: consider adding matches here
//         String(hex: flags)
//     }
// }
