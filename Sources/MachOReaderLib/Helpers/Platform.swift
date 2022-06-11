import Foundation

public struct Platform: RawRepresentable, Equatable {

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

    static let macOS = Platform(PLATFORM_MACOS)
    static let iOS = Platform(PLATFORM_IOS)
    static let watchOS = Platform(PLATFORM_WATCHOS)
    static let bridgeOS = Platform(PLATFORM_BRIDGEOS)
    static let macCatalyst = Platform(PLATFORM_MACCATALYST)
    static let iOSSimulator = Platform(PLATFORM_IOSSIMULATOR)
    static let tvOSSimulator = Platform(PLATFORM_TVOSSIMULATOR)
    static let watchOSSimulator = Platform(PLATFORM_WATCHOSSIMULATOR)
    static let driverKit = Platform(PLATFORM_DRIVERKIT)
}

// MARK: - Readable

extension Platform: Readable {

    public var readableValue: String? {
        switch self {
        case .macOS: return "macOS"
        case .iOS: return "iOS"
        case .watchOS: return "watchOS"
        case .bridgeOS: return "bridgeOS"
        case .macCatalyst: return "macCatalyst"
        case .iOSSimulator: return "iOSSimulator"
        case .tvOSSimulator: return "tvOSSimulator"
        case .watchOSSimulator: return "watchOSSimulator"
        case .driverKit: return "driverKit"
        default: return nil
        }
    }
}
