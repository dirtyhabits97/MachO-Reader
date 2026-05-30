# Makefile for MachO-Reader
#
# Common development tasks wrapped as make targets so local and CI runs
# share the exact same commands.

# Binary passed to `make run`. Defaults to the test fixture.
BINARY ?= Tests/MachOReaderLibTests/Fixtures/helloworld

# Treat extra goals after `run` as the binary path: `make run <path>`.
RUN_ARGS := $(filter-out run,$(MAKECMDGOALS))
ifeq (run,$(firstword $(MAKECMDGOALS)))
# Swallow the path argument so make doesn't try to build it as a target.
$(eval $(RUN_ARGS):;@:)
endif

.PHONY: all build build-release run install uninstall test lint format dev-deps help

all: help

## build: Compile the entire package
build:
	swift build

## build-release: Compile the entire package in release mode
build-release:
	swift build -c release

## run: Run the CLI against a binary (`make run [subcommand] <path>`, defaults to the fixture)
run:
	swift run macho-reader $(or $(RUN_ARGS),$(BINARY))

## install: Build and install macho-reader into $HOME/bin (no sudo)
install: build-release
	@mkdir -p $$HOME/bin
	@install -m 0755 .build/release/macho-reader $$HOME/bin/macho-reader
	@echo "Installed macho-reader to $$HOME/bin/macho-reader"
	@which macho-reader >/dev/null 2>&1 || ( \
		echo 'export PATH="$$HOME/bin:$$PATH"' >> $$HOME/.zshrc && \
		echo 'Added $$HOME/bin to PATH in ~/.zshrc — restart your shell or run: source ~/.zshrc' )

## uninstall: Remove macho-reader from $HOME/bin
uninstall:
	@rm -f $$HOME/bin/macho-reader
	@echo "Removed $$HOME/bin/macho-reader"

## test: Run the full test suite
test:
	swift test

## lint: Check formatting and linting without modifying files
lint: dev-deps
	swiftlint --strict
	swiftformat --lint .

## format: Apply formatting to all sources
format: dev-deps
	swiftformat .

## dev-deps: Ensure swiftlint and swiftformat are installed
dev-deps:
	@command -v swiftlint >/dev/null 2>&1 || { echo "Installing swiftlint..."; brew install swiftlint; }
	@command -v swiftformat >/dev/null 2>&1 || { echo "Installing swiftformat..."; brew install swiftformat; }

## help: List available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
