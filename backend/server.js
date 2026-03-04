const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Simulation d'une grille de 10x10
let grid = Array(10).fill(null).map(() => Array(10).fill("#FFFFFF"));

// Route pour récupérer la grille
app.get('/api/grid', (req, res) => {
    res.json(grid);
});

// Route pour modifier un pixel
app.post('/api/pixel', (req, res) => {
    const { x, y, color } = req.body;
    if (x >= 0 && x < 10 && y >= 0 && y < 10) {
        grid[y][x] = color;
        return res.status(200).json({ message: "Pixel mis à jour !" });
    }
    res.status(400).json({ error: "Coordonnées invalides" });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend Pixel War lancé sur le port ${PORT}`);
});