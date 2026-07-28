# Meets

![Swift](https://img.shields.io/badge/Swift-6.3-F05138)
![iOS](https://img.shields.io/badge/iOS-26+-5856D6)
![Xcode](https://img.shields.io/badge/Xcode-26.6-147EFB)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-4CAF50)

## Overview

What the application does, who it is for, the shape it takes, and anything else
worth knowing before the setup. Replace this section once the project has
something to say, the rest of this file describes the scaffolding and stays as
it is.

## Features

What the application can do, one line each, written for someone deciding
whether to look further.

- A capability worth naming.
- Another one.

## Setup

```bash
Scripts/bootstrap.sh
```

The badges above name the versions the project is built against, and `Homebrew`
is the one thing expected to be installed already. Everything else is brought in
by the script, which installs the version manager, compiles the pinned tools
from source, links them onto the path, and activates the git hooks. The first
run can take up to fifteen minutes, later runs reuse a shared cache and finish
in seconds. After that the toolchain watches itself, whenever the files that
describe it change, the next build, checkout, or assistant session says so and
tells you to run the script again. Nothing is ever reinstalled behind your back.

## Automations

The formatter and the linter split responsibilities. The formatter shapes the
code, everything it can repair on its own is disabled in the linter, so the
linter only ever reports what a person must actually think about.

**While editing.** An `Xcode` build phase runs the linter in strict mode and
shows findings inline. Another phase checks that the toolchain is current and
raises a warning in the issue navigator when it is not. Assistant edits are
formatted and linted immediately after they land.

**At commit time.** The pre commit hook formats the staged files and stages the
fixes, then lints them in strict mode. The commit message hook keeps messages
in the conventional style, it fixes what it can and rejects what it cannot,
showing the expected shape.

**After updating the working copy.** A merge, checkout, or rebase that changes
any file describing the toolchain prints a short notice saying what to run.

**In the pipeline.** Continuous integration installs the same pinned tools,
checks formatting in report only mode, lints in strict mode, builds for a
generic simulator destination, and runs the application and module suites once
they exist. The local scripts step aside on the runner, the pipeline checks the
whole tree itself. A separate check keeps pull request titles conventional.

**At release time.** Merging to the trunk keeps a release pull request up to
date with the next version and the changelog entry, and merging that pull
request is what releases. `CONTRIBUTING.md` carries the procedure.

## Distribution

Building for the `App Store` is deliberately not wired up. The version is
already centralized in `Configs/Version.xcconfig` and derived from the commit
history, so adding `fastlane` or `Xcode Cloud` later is a matter of pointing it
at that file, not of reworking how versions are decided. Nothing has to be
undone first.
