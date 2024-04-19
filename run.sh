#!/usr/bin/env bash

set -euo pipefail

# If bazel is installed
if command -v bazel &> /dev/null; then
  bazel run //Sources/MachOReaderCLI:MachOReaderCLI "$@"
# Default to spm
else
  swift build -c "release" --disable-sandbox
  ./.build/release/macho-reader "$@"
fi
