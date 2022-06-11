import Foundation

// TODO: document this
protocol LoadCommandTypeRepresentable {

    static var allowedCmds: Set<Cmd> { get }

    static func build(from loadCommand: LoadCommand) -> LoadCommandType
}

extension LoadCommand {

    func `is`(_ type: LoadCommandTypeRepresentable.Type) -> Bool {
        type.allowedCmds.contains(cmd)
    }
}
