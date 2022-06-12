import MachOReaderLib

extension Cmd: CLIOutput {

    var cli: String {
        readableValue ?? .cmd(rawValue)
    }
}

extension CPUType: CLIOutput {

    var cli: String {
        if let readableValue = readableValue {
            return "\(readableValue.padding(toLength: 7, withPad: " ", startingAt: 0)) (\(rawValue))"
        }
        return String(rawValue)
    }

    var cliCompact: String { readableValue ?? String(rawValue) }
}

extension FileType: CLIOutput {

    var cli: String {
        readableValue ?? .filetype(rawValue)
    }
}

extension Magic: CLIOutput {

    var cli: String {
        if let readableValue = readableValue {
            return "\(readableValue) \(String.magic(rawValue))"
        }
        return .magic(rawValue)
    }
}

extension MachOHeader.Flags: CLIOutput {

    var cli: String {
        readableValue ?? .flags(rawValue)
    }
}
