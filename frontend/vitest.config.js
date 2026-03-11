import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true, // Permet d'utiliser describe, it, expect sans les importer
    setupFiles: ["./src/setupTests.js"], // Charge le pont créé à l'étape 1
  },
});
