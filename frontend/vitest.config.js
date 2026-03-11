import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom", // C'est cette ligne qui règle l'erreur "document is not defined"
    globals: true,
    setupFiles: "./src/setupTests.js",
  },
});
