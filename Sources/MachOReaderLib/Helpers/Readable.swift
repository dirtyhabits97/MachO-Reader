/// A type with human readable representation.
public protocol Readable {

    /// The human readable string value of a raw type.
    ///
    /// Example:
    /// If the magic value is `0xfeedfacf`, the readable value would be `MH_MAGIC_64`.
    var readableValue: String? { get }
}
