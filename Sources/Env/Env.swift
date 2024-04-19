import Foundation

public let env = Env()

@dynamicMemberLookup
public final class Env {

    private var envVars: [String: String] { ProcessInfo.processInfo.environment }

    public subscript(key: String) -> String? {
        envVars[key]
    }

    // MARK: - DynamicMemberLookup

    public subscript(dynamicMember member: String) -> String? {
        envVars[member]
    }
}
