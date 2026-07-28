#!/usr/bin/env bash

# An optional build step that surfaces linter findings inline in the editor
# while writing code. Uses the pinned lint tool version.

set -uo pipefail

# Skip when the continuous integration environment variable is set.
# Linting is expected to run as a separate step in the pipeline.
[[ -n "${CI:-}" ]] && exit 0

# Build steps start with a bare search path, so widen it first.
export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

cd "${SRCROOT:-$(git rev-parse --show-toplevel)}" || exit 0

if ! command -v mint >/dev/null 2>&1; then
  echo "Mint is not installed. Run the bootstrap script to enable the linter in Xcode."
  exit 0
fi

mint run swiftlint lint --quiet --strict
