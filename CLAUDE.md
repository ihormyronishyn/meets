# Meets

## Overview
- Language: Swift 6.3
- Minimum Deployment Target: iOS 26
- Interface Framework: SwiftUI
- Package Manager: Swift Package Manager
- Testing Framework: Swift Testing
- Concurrency: Swift 6 strict, types crossing actor boundaries are `Sendable`
- Modules: local packages under `Modules/`, one package per leaf folder
- Version: `Configs/Version.xcconfig`, owned by the release automation on the trunk
- Workflow: branching, releasing, and the reasoning behind both live in `CONTRIBUTING.md`

## Structure
- Application sources live in `Meets/`, a single target.
- Shared and feature code lives in local packages under `Modules/`.
- Build settings live in `Configs/`, developer scripts in `Scripts/`.
- The pipeline and its configuration live in `.github/`.
- A module may depend on the layers below it, never on the layers above or on a sibling.

## Architecture
The application follows MVVM pattern with a coordinator,
one responsibility per layer, and every dependency pointing inward.
- Pattern: a view renders state and forwards intent, a view model owns the state of one screen and drives the services behind it, and a coordinator owns navigation and builds the two together. A view knows nothing of services or routes, a view model knows nothing of where a route leads, and a coordinator knows nothing of the state of a screen.
- State: the state of a screen lives in its view model, which is `@Observable` and `@MainActor`, and is mutated by that view model alone. Views observe it and never hold a copy of it.
- Navigation: a feature declares a routing protocol naming the outcomes of its screen, such as `didSomething(argument:)`, and knows nothing beyond it. Main app coordinator conforms to every one of those protocols, one extension per feature, and each extension holds the factory that builds the view model, injects its services, assigns the coordinator as its router, and returns the view. Routes are declared as properties of the coordinator, so the map of the application is readable in one file.
- Dependencies: a view model receives what it needs through its initializer, as protocols rather than concrete types, so a test substitutes a double without touching the code under test. The coordinator is the composition root and the only place a concrete service is built.
- Boundaries: features depend on shared modules, shared modules depend on core modules. A feature never imports another feature, the coordinator is what joins them. Only value types cross a boundary, entities and events, never a view or a view model of another feature.

## Integration
Use XcodeBuildMCP for all Xcode operations.
- Build: `mcp__xcodebuildmcp__build_sim`
- Test: `mcp__xcodebuildmcp__test_sim`
- Clean: `mcp__xcodebuildmcp__clean`
- Run: `mcp__xcodebuildmcp__build_run_sim`

Tool names track the pinned server version, so revisit this list when that version changes.

## Conventions
- Use `@Observable` macro instead of `ObservableObject`.
- Use `async/await` for all async operations.
- Use `guard` for early exits.
- Prefer value types over reference types where appropriate.
- Extract views when they exceed 100 lines.
- Types crossing actor boundaries are `Sendable`.
- Use `// MARK: -` section headers with `Properties`, `Init`, `Methods`, `Body`, `Preview` and a trailing `//: <Container>` comment on closing braces of views containers.

## Testing
- Write tests with Swift Testing, `@Test` and `#expect`, not XCTest.
- Put the tests of a module in the `Tests/` folder of that package.
- Give a test the name of the behavior it pins, one behavior per test.
- Keep tests deterministic and independent of the order they run in.
- Cover branches, edge cases, and error paths, not trivial accessors.

## Comments
- Write `//` comments as concise prose that explains intent.
- Use only commas and periods as punctuation.
- Write without apostrophes and without shortened forms, so rephrase a possessive and spell a word out in full.
- Refer to tools by their role instead of by name.
- These conventions do not apply to `///` documentation comments.

## Commits
- Follow the conventional style specification.
- Use one of these types, `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.
- Format the summary as `type(scope): description`, where the scope is optional.
- Use only lowercase letters for the type and description.
- Use only lowercase letters, digits, `.`, `_`, `/`, and `-` in the scope.
- Write the description in the imperative mood.
- Do not end the summary with a period.
- Keep the summary within 72 characters.
- Add a body only when additional context is needed.
- Separate the body from the summary with one blank line.
- Wrap the body at 72 characters.
- Add footers only when required, separated from the body by one blank line.
- Never use `--no-verify` or bypass hooks in any other way.

## Ownership
- The release automation writes `CHANGELOG.md` and `.release-please-manifest.json`, never edit them by hand.
- It also owns `Configs/Version.xcconfig` on `main`, on a release branch bump it with `Scripts/set-version.sh`.
- A hook formats and lints every edit after it lands, so do not run the formatter by hand.
