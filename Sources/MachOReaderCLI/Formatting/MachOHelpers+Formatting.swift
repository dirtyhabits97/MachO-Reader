import MachOReaderLib

extension Cmd: CLIOutput {

    var summary: String {
        readableValue ?? .cmd(rawValue)
    }
}

extension CPUType: CLIOutput {

    var summary: String {
        readableValue ?? String(rawValue)
    }

    var detailed: [String] {
        guard let readableValue else { return [String(rawValue)] }
        return ["\(readableValue.padding(toLength: 7, withPad: " ", startingAt: 0)) (\(rawValue))"]
    }
}

extension FileType: CLIOutput {

    var summary: String {
        readableValue ?? .filetype(rawValue)
    }
}

extension Magic: CLIOutput {

    var summary: String {
        if let readableValue = readableValue {
            return "\(readableValue) \(String.magic(rawValue))"
        }
        return .magic(rawValue)
    }
}

extension Platform: CLIOutput {

    var summary: String {
        readableValue ?? String(rawValue)
    }
}
