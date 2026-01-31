import Foundation

public let env = Env()

@dynamicMemberLookup
public final class Env: Sendable {

    private let processInfo: ProcessInfo
    private var envVars: [String: String] {
        processInfo.environment
    }

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    public subscript(key: String) -> String? {
        envVars[key]
    }

    // MARK: - DynamicMemberLookup

    public subscript(dynamicMember member: String) -> String? {
        envVars[member]
    }
}
