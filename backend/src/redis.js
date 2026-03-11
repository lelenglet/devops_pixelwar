import Redis from "ioredis";
import { config } from "./config.js";

export const redis = new Redis(config.redisUrl);

// Pub/Sub client (important for scaling)
export const pub = new Redis(config.redisUrl);
export const sub = new Redis(config.redisUrl);