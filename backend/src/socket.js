import { Server } from "socket.io";
import { getGrid, setPixel } from "./pixel.service.js";
import { pub, sub } from "./redis.js";

export function initSocket(server) {
  const io = new Server(server, {
    cors: { origin: "*" }
  });

  // Synchronisation inter-pods
  sub.subscribe("pixel:update");
  sub.on("message", (channel, message) => {
    if (channel === "pixel:update") {
      const pixel = JSON.parse(message);
      io.emit("pixel:update", pixel);
    }
  });

  io.on("connection", async (socket) => {
    console.log("User connected:", socket.id);

    // Envoyer la grille complète au nouveau client
    const grid = await getGrid();
    socket.emit("grid:init", grid);

    socket.on("pixel:set", async ({ x, y, color }) => {
      const pixel = await setPixel(x, y, color);

      // Publier vers Redis pour broadcast multi-pods
      await pub.publish("pixel:update", JSON.stringify(pixel));
    });

    socket.on("disconnect", () => {
      console.log("User disconnected:", socket.id);
    });
  });
}