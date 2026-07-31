const http = require('http');
const { Server } = require('socket.io');

const PORT = Number(process.env.PORT) || 3000;

const server = http.createServer();
const io = new Server(server, { cors: { origin: '*' } });

// The client sends everything it knows about itself in the handshake, and a
// query carries strings only, so the numbers and flags are read back here.
function peerOf(socket) {
    const query = socket.handshake.query;

    return {
        username: query.username,
        roomId: Number(query.roomId),
        isCaller: query.isCaller === 'true'
    };
}

io.on('connection', async (socket) => {
    const { roomId, username } = socket.handshake.query;

    if (!roomId || !username) {
        console.log(`Refused ${socket.id}, the handshake carries no room or no username.`);
        socket.disconnect(true);
        return;
    }

    const peer = peerOf(socket);

    socket.join(roomId);
    console.log(`${username} joined room ${roomId}`, socket.id);

    // Only the others hear about an arrival, so a newcomer would see an empty
    // room and nobody could start a meeting. The people already here are sent
    // to the newcomer under the same name, which is what fills that list.
    const present = await io.in(roomId).fetchSockets();

    for (const other of present) {
        if (other.id === socket.id) {
            continue;
        }

        socket.emit('room_user_joined', peerOf(other));
    }

    socket.to(roomId).emit('room_user_joined', peer);

    // Descriptions and candidates go to the room rather than to one person,
    // because only an invitation names its addressee. The client drops what is
    // not addressed to it, which is enough while a room holds two people.
    socket.on('offer', (payload) => {
        console.log(`offer in room ${roomId}`);
        socket.to(roomId).emit('offer', payload);
    });

    socket.on('answer', (payload) => {
        console.log(`answer in room ${roomId}`);
        socket.to(roomId).emit('answer', payload);
    });

    socket.on('candidate', (payload) => {
        socket.to(roomId).emit('candidate', payload);
    });

    // This fires while the socket still belongs to its rooms, unlike the
    // disconnect that follows it, which runs once it has left them.
    socket.on('disconnecting', () => {
        socket.to(roomId).emit('room_user_left', peer);
        console.log(`${username} left room ${roomId}`, socket.id);
    });
});

server.listen(PORT, () => {
    console.log(`Signaling server listening on http://localhost:${PORT}`);
});
