# --- Stage 1 : Build ---
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Clean install : équivalent de npm install
RUN npm ci

COPY . .

RUN npm run build

# --- Stage 2 : Serve ---
FROM nginx:stable-alpine

# Copie du build React vers le dossier public de Nginx
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]