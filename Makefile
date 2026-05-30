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

.PHONY: all build run test lint format dev-deps help

all: help

## build: Compile the entire package
build:
	swift build

## run: Run the CLI against a binary (`make run <path>`, defaults to the fixture)
run:
	swift run macho-reader $(or $(RUN_ARGS),$(BINARY))

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
