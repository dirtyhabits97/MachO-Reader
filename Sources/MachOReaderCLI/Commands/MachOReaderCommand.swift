import ArgumentParser

@main
struct MachOReaderCommand: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "macho-reader",
                                                    abstract: "Parse and inspect Mach-O binaries.",
                                                    subcommands: [
                                                        InfoCommand.self,
                                                        DyldChainedFixupsCommand.self,
                                                        SymbolsCommand.self,
                                                    ],
                                                    defaultSubcommand: InfoCommand.self)
}
