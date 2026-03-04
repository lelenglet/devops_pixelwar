import { redis } from "./redis.js";
import { pool } from "./db.js";

const GRID_KEY = "pixel:grid";

// Charger toute la grille
export async function getGrid() {
  const grid = await redis.hgetall(GRID_KEY);
  return grid;
}

// Modifier un pixel
export async function setPixel(x, y, color) {
  const key = `${x}:${y}`;

  // Mise à jour Redis (live)
  await redis.hset(GRID_KEY, key, color);

  // Persistance PostgreSQL
  await pool.query(
    `INSERT INTO pixels (x, y, color)
     VALUES ($1, $2, $3)
     ON CONFLICT (x, y)
     DO UPDATE SET color = EXCLUDED.color`,
    [x, y, color]
  );

  return { x, y, color };
}