import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    proxy: {
      "/socket.io": {
        target: process.env.VITE_SOCKET_URL,
        ws: true,
        changeOrigin: true
      }
    }
  }
});