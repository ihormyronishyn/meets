# Contributing

## Commits

Messages follow the conventional style, a lowercase type word, an optional
scope, and a short imperative description within seventy two characters.

```
<type>([optional scope]): <description>

[optional body]

[optional footer(s)]
```

The commit message hook enforces this locally. See `CLAUDE.md` for the full
type list and formatting rules. Never bypass the hooks with `--no-verify`.

## Branching

This project uses a trunk based model with a release train. There is one long
lived branch, `main`, and short lived branches that merge back into it. Release
branches are cut only when a version is being stabilized for the `App Store`.

### Trunk

`main` is always green and always releasable. Every push and every pull request
that targets it runs the full gate, formatting, linting, and a build. Direct
pushes are disabled by branch protection, changes arrive through pull requests
only.

### Work

Branch off `main`, prefixing the branch with the commit type of the work, so
the branch, its commits, and the changelog entry line up. The scope is the
module the work touches.

| Prefix | For |
| --- | --- |
| `feat` | new functionality or a new module |
| `fix` | a bug fix |
| `refactor`, `perf` | changes with no new behavior |
| `test` | adding or widening tests |
| `chore`, `ci`, `docs` | tooling, pipeline, documentation |

Open a pull request into `main`, let the gate pass, and merge with squash. A
review is welcome but not required, the green gate is what guards the trunk.
The squash commit takes its message from the pull request title, not from the
commits being squashed, so the title must itself be conventional. A separate
check holds titles to the same shape the commit hook holds local messages to.

### Stabilization

When a version is ready to stabilize, cut `release/<major>.<minor>` from `main`
at the feature freeze, then set the version on it. The branch inherits whatever
the trunk released last, and the pipeline requires a release branch to carry a
version from the series it names, so a cut without a bump fails its first run.

```bash
git switch -c release/1.0 main
Scripts/set-version.sh 1.0.0
git commit -am "type(optional scope): 1.0.0"
```

From that point `main` keeps moving with the next version. The release branch
takes only stabilizing fixes and runs the same gate. When the build is
accepted, tag it `v<major>.<minor>.<patch>` there. The tag, not the branch,
marks the released commit.

### Fixes

A fix for a release branch lands on `main` first, then travels to the release
branch as a cherry pick. Never the other way around.

```bash
git switch release/1.0
git cherry-pick <sha-from-main>
```

A fix authored on a release branch only reaches the next version if someone
remembers to bring it back, and the release that forgets is the one that
reintroduces the bug. Landing on the trunk first makes that impossible, the
cherry pick can then be forgotten without consequence.

The one exception is a production incident where `main` is not shippable, which
may be fixed on the release branch directly. Bringing the same fix to `main` is
then part of the incident, not an afterthought.

### Hotfixes

For an urgent fix to a version whose release branch is gone, branch
`hotfix/<desc>` from the released tag, apply the fix, bump the version, and tag
the new patch. Land it on `main` too, by cherry pick, since `main` keeps a
linear history and cannot take a merge commit.

## Structure

Code is organized into local Swift packages under `Modules/`. How they are
grouped is an architectural choice, the pipeline only asks that a package sits
somewhere below that folder.

```
Modules/
  <group>/
    <module>/
      Package.swift
      Sources/
      Tests/
```

- **One package per leaf.** A leaf folder holds a `Package.swift`, the folders
  above it only group, and they may nest as deep as the architecture needs.
- **The package name matches its folder.** The pipeline derives the scheme it
  tests from the leaf folder name, so the `name` of a package and its folder
  must agree.
- **Tests live in `Tests/`.** A module is tested when that folder is present
  and not empty, the standard layout of the package manager. Modules without
  tests are skipped, not failed.
- **Modules build for the simulator.** They are tested on a simulator like the
  application, so they may depend on the interface frameworks of the platform.
- **Dependencies point inward.** A module may depend on the layers below it,
  never on the layers above, and never on a sibling in its own layer. When two
  modules need the same thing, it moves down a layer.

The commit scope is the module name, matching the branch and the changelog
entry.

## Versioning

Versions follow semantic versioning and are derived from the conventional
commit types on `main`, which is why the commit format is enforced.

| Commit | Bump |
| --- | --- |
| `fix:` or `perf:` | patch |
| `feat:` | minor |
| `feat!:` or a `BREAKING CHANGE:` footer | major |

The version lives in `Configs/Version.xcconfig` as `MARKETING_VERSION`, not in
the project file, so it can be bumped in a commit. On `main` the release
automation owns it and it is never edited by hand. On a `release/*` or
`hotfix/*` branch, where that automation does not reach, bump it with
`Scripts/set-version.sh`.

`CURRENT_PROJECT_VERSION` is the build number and matters only when uploading
to `App Store Connect`, so it is left to whoever performs that upload.

That file holds the version and nothing else, because the automation owns the
whole file and a second author would collide with it on every release. Other
build settings belong beside it in `Configs/`, behind a `Configs/Base.xcconfig`
set as the base configuration of the target.

```
// Configs/Base.xcconfig
#include "Version.xcconfig"
#include? "Config.xcconfig"
```

The optional include is where machine local values such as tokens go.
`Config.xcconfig` is ignored by version control and unreadable to the
assistant, and the optional form means a checkout without one still builds.

## Releases

Releasing the trunk is automated. The release automation keeps a pull request
open that accumulates the next version, the version bump, and the
`CHANGELOG.md` entry from the commits that have landed. Review it when you are
ready, it runs the same gate as any other change. Merging it is the release,
the automation tags the version on the trunk and publishes the release with the
changelog section as its notes.

Nothing is released by merging ordinary work, only by merging that pull
request, which keeps the timing a deliberate decision.

The version is kept in one place. The automation writes it to
`Configs/Version.xcconfig` and tracks it in `.release-please-manifest.json` for
itself. Its own default version file is never created, because a file it would
only update when already present is simply not shipped.

The first release is 1.0.0. The manifest starts empty, so the automation reads
the first release pull request as an initial one and takes its version from
`initial-version` in `release-please-config.json`, rather than computing a bump
above a baseline nobody released.

### Setup

This is a one time setup for whoever owns the repository, not a step any
contributor performs. Four things have to be in place before the first release.
The token is the one that used to be easy to miss, because a release without it
failed in a way that looked like nothing happening, so the workflow now checks
it first and refuses to run without a working one.

- **Allow the workflows to open pull requests.** The setting is under
  `Settings → Actions → General → Workflow permissions`, and without it the
  release pull request cannot be opened at all.
- **Add a `RELEASE_PLEASE_TOKEN` secret**, holding a token that belongs to an
  integration or to a person, with permission to write contents and pull
  requests. A pull request opened with the default workflow token cannot start
  another workflow, so the gate would never run on it and a required check
  would keep it unmergeable. There is no fallback to the default token, because
  falling back produced the worst failure of the four, a release pull request
  waiting forever for a status nobody sends, which reads as a stuck pipeline
  rather than as a missing secret. The workflow checks the secret before it
  does anything else instead, and stops with an error naming the fix when the
  secret is absent, expired, revoked, or scoped to another repository.
- **Protect `main`.** Require a pull request, the `Verify` and `Conventional`
  checks, a branch up to date with the trunk, linear history, and no force
  pushes or deletion. Each check appears in the list after its first run. A
  required check is matched by the name of the job, so renaming one later
  leaves the protection waiting on a check nobody sends, and pull requests
  hang without an error.
- **Squash only.** Under `Settings → General → Pull Requests`, allow only
  squash merging and set the default commit message to the pull request title,
  which is what makes every commit on the trunk a checked conventional message.

### Branches

The trunk automation does not manage release branches, so a release from one is
a version bump and a tag.

```bash
Scripts/set-version.sh 1.0.1
git commit -am "type(optional scope): 1.0.1"
git tag v1.0.1
git push origin release/1.0 v1.0.1
```

Pushing the tag publishes the release. A tag that already has one is left
untouched, so the two paths never collide. The notes are the changelog section
for that version when one exists, and generated from the commits when it does
not, which is the usual case here.

The pipeline checks that the version and the branch or tag agree, so a
forgotten bump fails the run instead of shipping a build that misreports its
own version.

Then tell the trunk about it, since the automation only knows the versions it
released itself. Open a pull request against `main` setting the released
version in `.release-please-manifest.json`. Skipping this leaves the automation
computing from a stale baseline, and its next release fails trying to create a
tag that already exists. This is the one case where that file is edited by
hand.

On `main`, changelog entries and version bumps are otherwise written by the
tooling. Do not edit `CHANGELOG.md`, `Configs/Version.xcconfig`, or
`.release-please-manifest.json` by hand there.


## Checklist

- The title is a conventional message, it becomes the squash commit.
- The local hooks have formatted and linted your staged changes on commit.
- The branch is up to date with `main`.
- New behavior is covered by tests.
- The pipeline is green.
