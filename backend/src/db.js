import pkg from "pg";
import { config } from "./config.js";

const { Pool } = pkg;

export const pool = new Pool({
  connectionString: config.pgUrl,
});

export async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS pixels (
      x INT NOT NULL,
      y INT NOT NULL,
      color VARCHAR(7) NOT NULL,
      PRIMARY KEY (x, y)
    );
  `);
}