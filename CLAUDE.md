# AGENTS.md - Development Guide for MachO-Reader

This guide provides essential information for AI coding agents working in this repository.

## Project Overview

MachO-Reader is a Swift package for parsing Mach-O (Mach Object) binary file formats used by macOS and iOS executables. The project consists of:
- **MachOReaderLib**: Core library for parsing Mach-O files
- **MachOReaderCLI**: Command-line interface executable
- **Env**: Environment variable handling utility

## Build & Test Commands

### Building
```bash
# Build entire package
swift build

# Build specific targets
swift build --target MachOReaderCLI
swift build --target MachOReaderLib

# Run the CLI
swift run macho-reader <path-to-binary>
```

### Testing
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter MachOReaderLibTests
swift test --filter EnvTests

# Run single test class
swift test --filter MachOHeaderTests

# Run single test method
swift test --filter MachOHeaderTests.test_oneHeader_whenOnlyOneArchIsSupported
```

### Linting & Formatting
```bash
# SwiftLint (installed separately)
swiftlint lint --strict

# SwiftFormat (installed separately)
swiftformat --lint .
swiftformat .
```

## Code Style Guidelines

### Imports
- Group imports with Foundation first, then MachO, then project modules
- Keep imports minimal and specific
```swift
import Foundation
import MachO
import MachOReaderLib
```

### File Structure & Organization
```swift
// 1. Imports
import Foundation

// 2. Type definition with MARK comments
public struct TypeName {
    
    // MARK: - Properties
    
    public let property: Type
    private let privateProperty: Type
    
    // MARK: - Lifecycle
    
    init(from data: Data) {
        // initialization
    }
    
    // MARK: - Methods
    
    public func method() {
        // implementation
    }
}

// 3. Extensions with MARK
// MARK: - CustomStringConvertible

extension TypeName: CustomStringConvertible {
    public var description: String {
        "description"
    }
}
```

### Naming Conventions
- **Types**: PascalCase (e.g., `MachOHeader`, `LoadCommand`, `BuildVersionCommand`)
- **Functions/Methods**: camelCase with descriptive names (e.g., `getBuildVersionCommand()`, `getDylibCommands()`)
- **Properties**: camelCase (e.g., `magic`, `cputype`, `filetype`)
- **Constants**: camelCase for local, PascalCase for global (e.g., `kByteSwapOrder`)
- **Test methods**: `test_expectedBehavior_whenCondition` format

### Types & Properties
- Use explicit types for public APIs: `public let property: Type`
- Use `let` over `var` whenever possible (immutability preferred)
- Mark properties `private` unless they need to be public
- Use property observers sparingly
- Prefer structs over classes unless reference semantics are needed
- Use `final` for classes that shouldn't be subclassed

### Access Control
- Default to `internal` (omit keyword)
- Mark public API with `public`
- Use `private` for internal implementation details
- Avoid `fileprivate` unless necessary

### Error Handling
- Use `throws` for recoverable errors in public APIs:
```swift
public init(from url: URL, arch: String?) throws {
    file = try MachOFile(from: url, arch: arch)
}
```

- Use `guard` with early return for validation:
```swift
guard let url = helloWorldURL else { return }
guard magic.isFat else { return nil }
```

- Use `fatalError()` for programmer errors (should never happen in production):
```swift
guard let url = URL(string: "file://\(pathToBinary)") else {
    fatalError("Could not create url for \(pathToBinary)")
}
```

- Use assertions for debug-time validation:
```swift
assert(loadCommand.is(BuildVersionCommand.self),
       "\(loadCommand.cmd) doesn't match any of \(BuildVersionCommand.allowedCmds)")
```

### Code Patterns

**Functional transformations:**
```swift
// Use compactMap for filtering + transforming
public func getDylibCommands() -> [DylibCommand] {
    file.commands.compactMap { loadCommand in
        guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }
        return dylibCommand
    }
}

// Use lazy when appropriate for performance
file.commands.lazy.compactMap { ... }.first
```

**Pattern matching:**
```swift
// Use guard case for single pattern extraction
guard case let .dylibCommand(dylibCommand) = loadCommand.commandType() else { return nil }

// Use if case for conditional execution
if case let .buildVersionCommand(cmd) = loadCommand.commandType() {
    return cmd
}
```

## SwiftLint Configuration

Current rules (`.swiftlint.yml`):
- Strict mode enabled
- Line length: flexible with comments ignored
- Disabled: `large_tuple`, `todo`, `trailing_comma`
- Scope: `Sources/` and `Tests/` directories

## SwiftFormat Configuration

Disabled rules (`.swiftformat`):
- `blankLinesAtStartOfScope`
- `redundantParens`

## Testing Guidelines

### Test Structure
```swift
@testable import MachOReaderLib
import XCTest

final class TypeNameTests: XCTestCase {
    
    func test_expectedBehavior_whenCondition() throws {
        // Arrange
        guard let url = url(for: "fixture") else { return }
        
        // Act
        let result = try MachOFile(from: url, arch: nil)
        
        // Assert
        XCTAssertEqual(result.property, expectedValue)
    }
}
```

### Test Naming
- Test methods: `test_expectedBehavior_whenCondition`
- Use descriptive names that explain what is being tested
- Examples: `test_oneHeader_whenOnlyOneArchIsSupported`, `test_hasCommands_whenValidBinary`

### Assertions
- Prefer specific assertions: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil`
- Use `XCTAssertNoThrow` for error handling validation
- Always include failure messages for clarity

## File References

Mach-O header definitions are in Xcode SDK:
```
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/mach-o/loader.h
```

## Additional Notes

- Swift version: 5.6+
- Platform: macOS (primary), supports Darwin platforms
- Dependencies: swift-argument-parser (CLI only)
- Test fixtures are in `Tests/MachOReaderLibTests/Fixtures/`
