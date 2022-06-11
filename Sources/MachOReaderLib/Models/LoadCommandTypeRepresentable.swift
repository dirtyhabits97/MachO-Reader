import Foundation

/// A Type that can be built from MachO's LoadCommand object.
protocol LoadCommandTypeRepresentable {

    /// The cmds that can correctly build this Type.
    ///
    /// Example: `LC_SEGMENT` can build a SegmentCommand but not a
    /// BuildVersionCommand.
    static var allowedCmds: Set<Cmd> { get }

    /// Builds a `LoadCommandType` wrapper that contains this type.
    ///
    /// - parameter loadCommand: the loadCommand that contains the data
    /// to build this object.
    static func build(from loadCommand: LoadCommand) -> LoadCommandType
}

extension LoadCommand {

    /// Returns `true` if the `LoadCommand` can be used to create
    /// the `type` parameter.
    func `is`(_ type: LoadCommandTypeRepresentable.Type) -> Bool {
        type.allowedCmds.contains(cmd)
    }
}
