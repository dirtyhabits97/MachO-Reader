#!/usr/bin/env bash

set -euxo pipefail

swift build -c "release" --disable-sandbox
./.build/release/macho-reader "$@"
