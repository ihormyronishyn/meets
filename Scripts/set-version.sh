#!/usr/bin/env bash

# Sets the marketing version in the configuration.

# The release automation owns that file on the trunk, so this is for the
# branches it does not reach, a release branch being stabilized or a hotfix cut
# from a tag. It exists so the version is never edited by hand, the annotation
# the automation relies on is easy to lose and a mistyped version ships a build
# that misreports itself.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

FILE="Configs/Version.xcconfig"
VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage is Scripts/set-version.sh <major>.<minor>.<patch>" >&2
  exit 2
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Not a version, expected three numbers separated by dots, got $VERSION." >&2
  exit 2
fi

if [[ ! -f "$FILE" ]]; then
  echo "$FILE is missing." >&2
  exit 1
fi

CURRENT="$(awk -F'=' '/^MARKETING_VERSION/ {gsub(/[ \t]|\/\/.*/, "", $2); print $2}' "$FILE")"

if [[ "$CURRENT" == "$VERSION" ]]; then
  echo "Already at $VERSION."
  exit 0
fi

# The trailing annotation is what the release automation looks for, so it is
# rewritten with the line rather than left to chance.
tmp="$(mktemp)"
sed "s|^MARKETING_VERSION = .*|MARKETING_VERSION = $VERSION // x-release-please-version|" \
  "$FILE" > "$tmp"
mv "$tmp" "$FILE"

echo "Set the marketing version to $VERSION, was $CURRENT."
echo "Commit it, then tag the release."
