import { vi } from "vitest";
import "jest-canvas-mock";
import "@testing-library/jest-dom";

// On crée un pont entre Vitest et le mock qui attend du Jest
globalThis.jest = vi;
