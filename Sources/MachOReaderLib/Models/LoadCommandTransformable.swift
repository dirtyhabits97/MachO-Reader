import Foundation

/// A Type that can be transformed back into a LoadCommand.
public protocol LoadCommandTransformable {

    func asLoadCommand() -> LoadCommand
}
