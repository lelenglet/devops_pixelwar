import express from "express";
import http from "http";
import { config } from "./config.js";
import { initSocket } from "./socket.js";
import { initDB } from "./db.js";

const app = express();
const server = http.createServer(app);

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

async function start() {
  await initDB();
  initSocket(server);

  server.listen(config.port, () => {
    console.log(`Server running on port ${config.port}`);
  });
}

start();