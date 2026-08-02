# Meets

<img width="3840" height="2160" alt="banner" src="https://github.com/user-attachments/assets/62d3380b-7ad5-422a-b4c2-1cb59720e886" />

###

![Swift](https://img.shields.io/badge/Swift-6.3-F05138)
![iOS](https://img.shields.io/badge/iOS-26-5856D6)
![Xcode](https://img.shields.io/badge/Xcode-26.6-147EFB)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-4CAF50)
![WebRTC](https://img.shields.io/badge/WebRTC-150.0.0-A5B4FC)
![Socket.IO](https://img.shields.io/badge/Socket.IO-16.1.1-010101)
![Stinsen](https://img.shields.io/badge/Stinsen-2.0.15-FF8A65)
![Node](https://img.shields.io/badge/Node-22-339933)

## Overview

A video meeting between two people. One side names a room, the other names the
same room, and the two of them see and hear each other over a connection made
directly between the devices. A small server carries the invitation and the
addresses the two sides need in order to find each other, and steps out of the
way once they have.

The application is built as a set of local packages, one screen per package,
joined by a composition root that owns navigation and builds the services. The
point of the shape is that a screen can be read, tested, and changed without
opening the others.

## Features

- Sign in with a name and the number of a room, choosing which side opens the
  meeting.
- Watch the room fill and empty as people arrive and leave in real time.
- Start a meeting with somebody whose role is the opposite of yours, and answer
  one that somebody started with you.
- Camera and microphone both ways, over a connection made directly between the
  two devices rather than through a server.
- The other side fills the screen and your own picture sits in the corner, each
  saying whether it carries a video yet.
- Leave a meeting or a room only after saying so twice, since neither can be
  undone by going back.
- Hear why a room was not reached, whether nobody answered or it already holds
  the two people it takes.
- A recording stands in for the camera where there is none, so both sides of a
  meeting can be tried on one machine.
- Every visible word lives in a string catalog, and every screen is readable by
  an assistive reader.

## Implementation

**MVVM+C architecture.** A view renders state and forwards intent. A view
model owns the state of one screen, is `@Observable` and lives on the main
actor, and is the only thing that changes that state. A coordinator owns
navigation and builds the two together, and is the only place a concrete
service is made. None of the three knows what the others know, a view has never
heard of a service, a view model has never heard of a route.

**Features that cannot reach each other.** Each declares a protocol naming the
outcomes of its screen, `didLogin`, `didStartMeet`, and knows nothing beyond
it. The composition root conforms to every one of them, one extension per
feature, and each extension holds the factory that builds the view model,
injects its services, and returns the view. The map of the application is one
file, and a feature importing another one is not a rule to remember, it simply
does not compile.

**Nine packages in four layers.** `App` over `Features` over `Shared` over
`Core`. Dependencies point down and never sideways, which the package manifests
enforce on their own, since a package cannot see what it has not declared. The
composition root is a package like the rest, so the target of the application
holds an entry point and its resources and nothing else.

**Swift 6.** The language mode is `6` in every manifest. Services are
actors, everything crossing between them is `Sendable`, and the screens are on
the main actor by declaration rather than by hope. Where a framework type
cannot be made safe, the promise is made in one visible place instead of being
spread around.

**Tests written with Swift Testing.** 132 of them, a suite per package, all
named in one test plan so the pipeline runs exactly what a contributor runs. A
view model is tested through the protocols it was handed, with doubles that
open no socket and read nothing from the device, so the suite is deterministic
and needs no network. Where the compiler cannot see a mistake, a test does. The
names of the symbols of the system are asked of the system itself, and every
string catalog is read back through the bundle of its own module.

**Strings and symbols that do not compile when wrong.** Every visible word
lives in a catalog beside the screen that shows it, reached through a generated
symbol rather than a literal, so a misspelled key is a build failure rather
than a word rendered as its own key. The same holds for the symbols of the
system, which are named once and asked for by role.

## Boundaries

Two decisions are worth knowing before reading the code, because both are
deliberate and neither is a setting.

**A room holds two people.** The server turns the third away and says why.
This is not a policy, it is what the protocol requires. A session description
and a candidate name nobody, so a third person in the room would apply to their
own connection what two others said to each other. Raising the number means
carrying an addressee in every message, not changing a constant.

**Leaving a meeting drops the connection to the room.** Both share one socket,
so ending a meeting ends the connection behind the room as well, and the person
reconnects by hand on their return. It is accepted rather than overlooked.

There is also a limit worth expecting rather than debugging. The discovery
servers named in `Configs/Base.xcconfig` are all of the kind that only report
an address back, and none of the kind that relays traffic when a direct path
cannot be opened. On one machine or one network a meeting connects, behind two
restrictive networks it may not, and adding a relay is a matter of naming one
in that setting.

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

## Running

Nobody reaches a room until the signaling server is listening, so it is started
first and left running.

```bash
cd Server
npm install
npm start
```

It listens on port `3000`, which is where the application looks by default,
through `SIGNALING_SERVER_URL` in `Configs/Base.xcconfig`. `Server/README.md`
describes the handshake, the events, and how to move the port.

A meeting needs two sides, so run the application twice, on two simulators or
on a simulator and a device, and sign both into the same room with different
names. One of them turns the caller switch on and the other leaves it off,
since a meeting is opened by one side and answered by the other. A simulator
has no camera, and a recording stands in for one, so what the other side
receives is that recording rather than a black picture.

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
