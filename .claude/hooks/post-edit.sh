#!/usr/bin/env bash

# Runs after the assistant edits a swift file.
# Formats the code and runs the linter using the pinned tool versions,
# so findings match the commit gate and continuous integration.

set -uo pipefail

# Skip when the continuous integration environment variable is set.
# Separate step in the pipeline checks the whole tree on its own.
[[ -n "${CI:-}" ]] && exit 0

# Assistant sessions can start with a bare search path, so widen it first.
export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# The event arrives as structured data on the standard input, take only the
# path of the touched file from it.
FILE="$(python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null)"

[[ -n "$FILE" ]] || exit 0

# Only language sources are checked, everything else passes through.
case "$FILE" in
  *.swift) ;;
  *) exit 0 ;;
esac

# Checked out packages and build products are not ours to police.
case "$FILE" in
  */SourcePackages/* | */.build/* | */DerivedData/*) exit 0 ;;
esac

[[ -f "$FILE" ]] || exit 0

# Without the version manager there is nothing to run. The session start
# step performs the setup, so the tools will be there for the next edit.
command -v mint >/dev/null 2>&1 || exit 0

# Rewrite first, so the linter reads code the formatter has already
# finished, the same order the commit gate uses. A file in the middle of a
# larger change may not parse yet, so a formatter failure is not a finding.
mint run swiftformat "$FILE" --quiet >/dev/null 2>&1 || true

# A nonzero exit with the findings on the error stream returns them to the
# assistant for an immediate fix.
if ! FINDINGS="$(mint run swiftlint lint --quiet --strict "$FILE" 2>&1)"; then
  printf '%s\n' "$FINDINGS" >&2
  exit 2
fi

exit 0
