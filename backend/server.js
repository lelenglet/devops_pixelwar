import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';
import client from 'prom-client';

const app = express();
const httpServer = createServer(app);
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics(); // Capture CPU, RAM automatiquement

const connectedUsersGauge = new client.Gauge({
  name: 'pixelwar_connected_users',
  help: 'Number of currently connected users'
});

const totalPaintedCounter = new client.Counter({
  name: 'pixelwar_pixels_painted_total',
  help: 'Total number of pixels painted since server start'
});

const io = new Server(httpServer, {
  cors: {
    origin: "*", // Allow your frontend to connect
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

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
  connectedUsersGauge.inc();
  console.log("Client connected:", socket.id);

  // Send the full grid to the new user
  socket.emit("grid:init", grid);

  // Handle pixel updates
  socket.on("pixel:set", ({ x, y, color }) => {
    grid[`${x}:${y}`] = color;
    // Broadcast the change to EVERYONE (including the sender)
    io.emit("pixel:update", { x, y, color });

    totalPaintedCounter.inc()
  });

  socket.on("disconnect", () => {
    connectedUsersGauge.dec();
    console.log("Client disconnected");
  });
});

// Health check for Kubernetes
app.get('/health', (_, res) => res.send('OK'));

app.get('/metrics', async (_, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend running on port ${PORT}`);
});