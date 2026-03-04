# --- Stage 1 : Build ---
FROM node:20-alpine AS builder

WORKDIR /app

# Copier des fichiers de dépendances
COPY package*.json ./

# Installation des dépendances de prod
RUN npm ci --omit=dev
# RUN npm install --production

COPY . .

# --- Stage 2 : Run ---
FROM node:20-alpine

WORKDIR /app

# Copier uniquement ce qui est nécessaire
COPY --from=builder /app/node_modules ./node_modules

COPY . .

# User sans privilèges
USER node

EXPOSE 3000

CMD ["node", "server.js"]
