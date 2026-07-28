#!/usr/bin/env bash

# Prepares a developer machine to work on the project. It runs in two ways.
# A full run performs the whole setup. A reporting run only says whether the
# setup is still current, and installs nothing on its own.

# The reporting run compares a fingerprint of the files that describe the
# toolchain against a fingerprint saved after the previous setup. When they
# are equal it returns silently, so it is cheap to trigger on every build and
# on common actions that update the working copy. When they differ it says
# what to run and leaves the decision to the developer, because installing a
# pinned tool compiles it from source and that wait belongs to whoever asked
# for it. The first line of a report stands on its own, so a caller with room
# for one line can take that line alone.

set -euo pipefail

# Graphical tools tend to start with a bare search path, so widen it first
# to make sure the tooling installed for this user can be found.
export PATH="$HOME/.mint/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1

cd "$(git rev-parse --show-toplevel)"

# Fingerprint bookkeeping.

# The files whose contents decide whether this setup is still valid, which is
# a narrower set than the files that describe the tooling.
#
# A pinned version moving means the tools have to be installed again. A change
# to the hook definitions can introduce a hook that is not wired yet. A change
# to this script means the setup itself behaves differently. Nothing else
# qualifies, the remaining scripts are read fresh every time something invokes
# them, and their executable bit is carried by version control, so editing one
# changes behaviour without leaving the setup stale. Reporting those would
# spend attention on a report that asks for nothing, which is how a report
# people should act on gets ignored.
#
# The list is fixed rather than a glob, so adding a script does not silently
# widen it.
TOOLING_FILES=(Mintfile lefthook.yml Scripts/bootstrap.sh)

tooling_hash() {
  if command -v shasum >/dev/null 2>&1; then
    cat "${TOOLING_FILES[@]}" 2>/dev/null | shasum -a 256 | cut -d' ' -f1
  else
    cat "${TOOLING_FILES[@]}" 2>/dev/null | sha256sum | cut -d' ' -f1
  fi
}

GIT_DIR="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null ||
  git rev-parse --absolute-git-dir)"
STAMP_FILE="$GIT_DIR/bootstrap-stamp"
CURRENT_HASH="$(tooling_hash)"

if [[ "${1:-}" == "--check" ]]; then
  if [[ -f "$STAMP_FILE" && "$(cat "$STAMP_FILE")" == "$CURRENT_HASH" ]]; then
    # Still current, report nothing.
    exit 0
  fi
  # A saved fingerprint means the tools are present and something they are
  # described by has moved. No saved fingerprint means this machine has never
  # been set up, which is a much longer wait and is worth saying plainly.
  if [[ -f "$STAMP_FILE" ]]; then
    echo "The toolchain no longer matches its description, run the bootstrap script to bring the pinned tools back into synchronization."
    echo "A tool whose pinned version moved is compiled from source, which can take a few minutes."
  else
    echo "The pinned tools have not been set up on this machine yet, run the bootstrap script once to install them."
    echo "The first run compiles them from source and can take up to fifteen minutes, later runs reuse a shared cache and finish in seconds."
  fi
  exit 1
fi

# Anything else is a mistake worth naming, because the alternative is a long
# setup that nobody asked for.
if [[ -n "${1:-}" ]]; then
  echo "Unknown option $1." >&2
  echo "Run the script with no options for a full setup, or with --check to report only." >&2
  exit 2
fi

# The setup itself.

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required, install it first and run this again." >&2
  exit 1
fi

if ! command -v mint >/dev/null 2>&1; then
  echo "Mint is required, installing it now."
  brew install mint
fi

echo "Installing the pinned language tools."
echo "The first run compiles them from source and can take up to fifteen minutes."
echo "Later runs reuse a shared cache and finish in seconds."
export MINT_LINK_PATH="$HOME/.mint/bin"

# The version manager narrates every clone, build, and link on its output,
# which buries the short progress this script prints. Only that narration is
# dropped, anything the version manager reports as a problem still comes
# through on the error stream and stops the run.
mint bootstrap --link >/dev/null

echo "Making the helper scripts executable."
chmod +x Scripts/*.sh .claude/hooks/*.sh

echo "Activating the shared version control automation."
# The automation runner lists the hooks it wired on its output, dropped for
# the same reason, with its errors left to come through.
mint run lefthook install >/dev/null

printf '%s' "$CURRENT_HASH" > "$STAMP_FILE"

echo "Done. Pinned tool versions are now in use."
echo "Future toolchain changes reapply themselves after an update of the working copy or the next build."
