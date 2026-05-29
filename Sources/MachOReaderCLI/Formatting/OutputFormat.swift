import ArgumentParser

/// Output format for CLI results
enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case text
    case json
}
