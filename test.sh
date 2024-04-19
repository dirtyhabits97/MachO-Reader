#!/usr/bin/env bash

set -euo pipefail

# If bazel is installed
if command -v bazel &> /dev/null; then
  bazel run //:tidy
  bazel test //...
# Default to spm
else
  swift test
fi
