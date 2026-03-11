import { useEffect, useRef } from "react";
import { socket } from "./socket";

const GRID_SIZE = 500;
const PIXEL_SIZE = 10;

export default function CanvasGrid() {
  const canvasRef = useRef(null);
  const ctxRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    canvas.width = GRID_SIZE * PIXEL_SIZE;
    canvas.height = GRID_SIZE * PIXEL_SIZE;

    const ctx = canvas.getContext("2d");
    ctxRef.current = ctx;

    // Fond blanc
    ctx.fillStyle = "#FFFFFF";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Réception grille complète
    socket.on("grid:init", (grid) => {
      Object.entries(grid).forEach(([key, color]) => {
        const [x, y] = key.split(":").map(Number);
        drawPixel(x, y, color);
      });
    });

    // Réception update pixel
    socket.on("pixel:update", ({ x, y, color }) => {
      drawPixel(x, y, color);
    });

    return () => {
      socket.off("grid:init");
      socket.off("pixel:update");
    };
  }, []);

  function drawPixel(x, y, color) {
    const ctx = ctxRef.current;
    ctx.fillStyle = color;
    ctx.fillRect(
      x * PIXEL_SIZE,
      y * PIXEL_SIZE,
      PIXEL_SIZE,
      PIXEL_SIZE
    );
  }

  function handleClick(e) {
    const rect = canvasRef.current.getBoundingClientRect();

    const x = Math.floor((e.clientX - rect.left) / PIXEL_SIZE);
    const y = Math.floor((e.clientY - rect.top) / PIXEL_SIZE);

    const color = getRandomColor();

    socket.emit("pixel:set", { x, y, color });
  }

  function getRandomColor() {
    return "#" + Math.floor(Math.random() * 16777215).toString(16).padStart(6, "0");
  }

  return (
    <canvas
      ref={canvasRef}
      onClick={handleClick}
      style={{ border: "1px solid black", cursor: "crosshair" }}
    />
  );
}