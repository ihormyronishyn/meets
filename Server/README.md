# Signaling

A small server the application talks to while a meeting is being set up. It
carries invitations, session descriptions, and candidates between the two sides
and holds no state of its own beyond who is currently in which room. It is a
tool for development, it is not part of what ships.

## Running

```bash
cd Server
npm install
npm start
```

It listens on port `3000`, which is where the application looks by default,
through `SIGNALING_SERVER_URL` in `Configs/Base.xcconfig`. Set `PORT` to move
it, and change that setting to match.

## Handshake

A client announces itself in the query of the connection, and a query carries
strings, so the server reads the number and the flag back out.

| Key | Meaning |
| --- | --- |
| `roomId` | the room to join |
| `username` | the name the other side sees |
| `isCaller` | whether this side starts the meeting |

## Events

The names match `PeerEvent.Name` on the client, and the payloads match the
types it decodes.

| Event | Direction | Payload |
| --- | --- | --- |
| `room_user_joined` | to the room, and to a newcomer for each person already there | a peer |
| `room_user_left` | to the room | a peer |
| `offer` | relayed to the room | an invitation or a session description |
| `answer` | relayed to the room | an invitation or a session description |
| `candidate` | relayed to the room | a candidate |
| `room_full` | to a newcomer that is being turned away | the room and how many it holds |

Everything except an invitation reaches the whole room rather than one person,
because only an invitation names its addressee. The client drops what is not
meant for it, which is what the capacity below keeps sufficient.

## Capacity

A room holds two people, and the third to ask for one is told `room_full` and
disconnected. This is not a policy, it is what the protocol above requires. A
session description and a candidate name nobody, so a third person would apply
what two others said to each other, and their leaving would end a meeting they
were never part of.

The count is read from the adapter rather than by fetching the sockets of the
room, because fetching suspends, and two people arriving together would both
count a room neither of them had joined yet.

## Versions

The client pins `socket.io-client-swift` to `16.1.1`, which speaks the protocol
of Socket.IO `4`, so the dependency here has to stay on that major version.

The package carries no version of its own. The one version this repository
tracks lives in `Configs/Version.xcconfig` and belongs to the application.
