import pkg from "pg";
import { config } from "./config.js";

const { Pool } = pkg;

export const pool = new Pool({
  connectionString: config.pgUrl,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
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