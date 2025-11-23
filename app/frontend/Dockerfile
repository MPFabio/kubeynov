FROM node:18-alpine AS builder

WORKDIR /app

# Installer les dépendances système nécessaires
RUN apk add --no-cache python3 make g++

# Configurer npm pour être plus rapide
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-timeout 300000 && \
    npm config set fetch-retries 2

# Copier uniquement les fichiers de dépendances
COPY package.json ./

# Installer les dépendances avec cache optimisé (garder les optionnelles pour rollup)
RUN npm install --legacy-peer-deps --prefer-offline --no-audit

# Copier le reste et builder
COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

