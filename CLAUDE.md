# Development Guide

This file provides guidance for working with code in this repository.

## Project Overview

MachO-Reader is a Swift package for parsing the Mach-O binary format used by macOS/iOS executables. It is a learning playground, not a production tool. Three targets:
- **MachOReaderLib** — the parsing library (no third-party deps; uses the system `MachO` module)
- **MachOReaderCLI** — the `macho-reader` executable (depends on the lib + swift-argument-parser)
- **Env** — a small standalone environment-variable utility used only by tests

## Build, Test, Lint

Prefer the `make` targets — they wrap `swift`/tooling so local and CI runs stay in sync (`make help` lists all).

```bash
make build                          # swift build
make run <path>                     # runs CLI; defaults to the helloworld fixture if no path
make run chained-fixups <path>      # subcommands work too (args forwarded verbatim)
make install                        # build release + install macho-reader into $HOME/bin (no sudo)
make uninstall                      # remove it from $HOME/bin
make test                           # full suite
make lint                           # swiftlint --strict + swiftformat --lint (auto-installs both via brew)
make format                         # swiftformat .
```

Granular test runs go through swift directly:
```bash
swift test --filter MachOReaderLibTests
swift test --filter MachOHeaderTests
swift test --filter MachOHeaderTests.test_oneHeader_whenOnlyOneArchIsSupported
```

The CLI binary is `macho-reader`. The root command is a pure router whose **default subcommand is `info`**, so a bare path runs `info`; `chained-fixups` is the other subcommand:
```bash
swift run macho-reader <path> --header --format json     # default `info` subcommand
swift run macho-reader chained-fixups <path> --imports
```

## Architecture

### Parsing pipeline (the core flow)

`MachOFile.init` (`Models/MachOFile.swift`) is the entry point and drives everything:
1. **Validate magic** by peeking the first `UInt32` (`Magic(peek:)`), throwing `MachOFileError.invalidMagic` if unrecognized.
2. **Handle fat binaries** — if a `MachOFatHeader` is present, advance `data` to the slice matching the requested `arch` (a `CPUType`). The chosen slice's start is stored as `base` (needed later because chained-fixups offsets are relative to it).
3. **Parse the header** into `MachOHeader`, then **walk load commands**: starting at `header.size`, decode each `LoadCommand` and advance by its `cmdsize` for `header.ncmds` iterations.

A `LoadCommand` (`Models/LoadCommand.swift`) holds only the common `cmd`/`cmdsize` plus the raw `data` slice and an `isSwapped` flag (set when the magic indicates opposite endianness — byte-swapping uses the system `swap_*` functions with `kByteSwapOrder`).

### Load-command type dispatch (extend the parser here)

Load commands are parsed lazily into concrete types via `LoadCommand.commandType() -> LoadCommandType`. The `LoadCommandType` enum (`Models/LoadCommandType.swift`) has one case per supported command plus `.unspecified` for unknown ones. Dispatch is table-driven: its initializer iterates a list of `LoadCommandTypeRepresentable.Type`s and picks the first whose `allowedCmds` set contains this command's `cmd`.

**To add support for a new load command**, create a type in `Models/LoadCommandTypes/` conforming to `LoadCommandModel` (= `LoadCommandTypeRepresentable & LoadCommandTransformable`), then register it in both the `LoadCommandType` enum's case list and its initializer's `commandTypes` array. The protocol contract:
- `static var allowedCmds: Set<Cmd>` — which `LC_*` values this type handles
- `static func build(from:) -> LoadCommandType` — wraps it in the enum
- `func asLoadCommand() -> LoadCommand` — round-trips back to the raw command

### Reports (higher-level analyses)

Beyond per-command parsing, `Reports/` holds multi-step analyses. `DyldChainedFixupsReport` (`Models/MachOFile.swift` exposes it via `dyldChainedFixupsReport()`) reads the `LC_DYLD_CHAINED_FIXUPS` payload from `__LINKEDIT` (using `file.base` + `dataoff`), then runs a set of builder types (`DyldChainedImportBuilder`, `DyldChainedStartsInSegmentBuilder`, `DyldChainedSegmentPageInfoBuilder`) to produce imports, segment info, and page info.

### Binary decoding — two layers, one deprecated

- **`BinaryDecoder`** (`BinaryDecoding/`) is the current, safe API: bounds-checked, alignment-aware, throws `BinaryDecodingError`. Use `data.decode(T.self, at:)`, `decode(count:)`, `decodeString()`, or conform a type to `BinaryDecodable` for custom decoding. **Prefer this for all new code.**
- **`Data.extract(_:)` / `extractArray` / `extractString`** (`Extensions/Data+Extensions.swift`) is the older `@available(*, deprecated)` unsafe path (`withUnsafeBytes` loads, no bounds checks). Still used by existing models like `DylibCommand` and the `dyld_chained_*` structs (via `CustomExtractable`). Don't add new uses; migrate to `BinaryDecoder` when touching this code.

### C struct models

The system `MachO` module provides most C structs (`load_command`, `dylib_command`, `mach_header_64`, etc.). The `dyld_chained_*` fixup structs are **not importable** from `MachO.fixups`, so they're hand-redeclared in `CModels.swift` (with the original `fixup-chains.h` comments preserved). These intentionally violate `type_name`/`identifier_name` lint rules — note the `// swiftlint:disable` wrapping.

### Readable values

Enum-like wrappers (`Magic`, `Cmd`, `CPUType`, `FileType`, `Platform`, …) in `Helpers/` conform to `Readable`, exposing `readableValue: String?` to turn raw integer constants into their `LC_*` / `MH_*` symbolic names for display.

### CLI layer

`MachOReader` (`MachOReaderLib/MachOReader.swift`) is a thin facade over `MachOFile` with `getDylibCommands()`-style convenience accessors (each a `compactMap` + `guard case` over `commands`). The CLI (`Commands/`) is structured as a router + subcommands: `MachOReaderCommand` (the `@main` entry, `Commands/MachOReaderCommand.swift`) declares **no arguments of its own** — it only lists `subcommands` and sets `defaultSubcommand: InfoCommand.self`. The actual work lives in the subcommands, `InfoCommand` (default) and `DyldChainedFixupsCommand`. (This split is required: a parent command that owns a required positional argument can't coexist with subcommands — swift-argument-parser would consume the subcommand name as the positional.) Each subcommand parses its args, then routes to one of two formatters (`Formatting/TextFormatter`, `JSONFormatter`) based on `--format`. Both follow the same shape: a flag selects a sub-view (`--header`, `--dylibs`, `--imports`, …) and dispatches to `printText`/`printJSON`.

## Code Style

Run `make lint`/`make format` before finishing — swiftlint is in `--strict` mode. Conventions enforced/expected:

- **Imports**: Foundation first, then `MachO`, then project modules.
- **File layout**: `MARK: -` sections (`Properties`, `Lifecycle`, `Methods`), extensions for protocol conformances.
- **Naming**: Types PascalCase; methods/properties camelCase; test methods `test_expectedBehavior_whenCondition`.
- **Immutability**: `let` over `var`; `struct` over `class` unless reference semantics needed; `final` on classes; default to `internal`, mark `public` deliberately.
- **Errors**: `throws` for recoverable/public failures; `guard` + early return for validation; `fatalError()` only for programmer errors that should never occur; `assert(...)` for debug-time invariants (e.g. confirming `loadCommand.is(SomeCommand.self)` before building it).
- **Patterns**: `compactMap` for filter+transform over `commands`; `guard case let .x(y) = ...` to extract a single enum payload; `lazy` when only the first match is needed.

SwiftFormat disables `blankLinesAtStartOfScope` and `redundantParens`. SwiftLint disables `large_tuple`, `todo`, `trailing_comma`.

## Testing

Tests use XCTest (`@testable import MachOReaderLib`) with Arrange/Act/Assert structure. Fixtures live in `Tests/MachOReaderLibTests/Fixtures/` (the `helloworld` Mach-O binary is the main one) and are loaded via the `Fixtures.swift` helpers, then declared as `resources` in `Package.swift`. Several tests guard on the fixture URL and `return` early if absent rather than failing.

## Reference

Mach-O struct definitions live in the Xcode SDK (path varies by install):
```
.../iPhoneOS.sdk/usr/include/mach-o/loader.h
.../iPhoneOS.sdk/usr/include/mach/vm_prot.h
```
Swift 6.2+. The fixup-chains layout (not in the SDK's importable headers) is documented inline in `CModels.swift`.
