import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*", // Allow your frontend to connect
    methods: ["GET", "POST"]
  }
});

const PORT = 3000;

app.use(cors());
app.use(express.json());

// 10x10 Grid (Matches your frontend logic)
let grid = {}; 

// Initializing a simple grid object
for (let x = 0; x < 10; x++) {
  for (let y = 0; y < 10; y++) {
    grid[`${x}:${y}`] = "#FFFFFF";
  }
}

io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);

  // Send the full grid to the new user
  socket.emit("grid:init", grid);

  // Handle pixel updates
  socket.on("pixel:set", ({ x, y, color }) => {
    grid[`${x}:${y}`] = color;
    // Broadcast the change to EVERYONE (including the sender)
    io.emit("pixel:update", { x, y, color });
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

// Health check for Kubernetes
app.get('/health', (req, res) => res.send('OK'));

httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend running on port ${PORT}`);
});