import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import App from "./App";

describe("Composant App", () => {
  it("devrait afficher le titre Pixel War", () => {
    render(<App />);
    const titleElement = screen.getByText(/Pixel War/i);
    expect(titleElement).toBeInTheDocument();
  });
});
