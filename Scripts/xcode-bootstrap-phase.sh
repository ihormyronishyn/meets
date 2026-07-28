#!/usr/bin/env bash

# A thin wrapper meant to run as the very first build step.
# Checks whether the local tools are still current on every build and says so
# when they are not. Requires script sandboxing to be disabled.

set -uo pipefail

# Skip when the continuous integration environment variable is set.
# Project bootstrap is intended for local development only.
[[ -n "${CI:-}" ]] && exit 0

cd "${SRCROOT:-$(git rev-parse --show-toplevel)}" || exit 0

# The reporting run stays quiet while the setup is current. When it has
# something to say, the opening line carries the whole point, and marking it
# raises it in the issue navigator where it is read without stopping a build.
if ! REPORT="$(Scripts/bootstrap.sh --check)"; then
  echo "warning: $(printf '%s\n' "$REPORT" | head -n 1)"
fi

exit 0
